import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/outfit.dart';
import '../services/health_connect.dart';

enum Gender { male, female }

const int kDefaultGoal = 10000;
const int kCoinsPerAdWatch = 25;
const int _kHistoryDaysKept = 400;

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayKey() => dayKey(DateTime.now());

class GameState extends ChangeNotifier {
  Gender? _gender;
  int _todaySteps = 0;
  int _goal = kDefaultGoal;
  int _coins = 0;
  final Set<String> _owned = {defaultOutfitId};
  String _outfit = defaultOutfitId;

  /// Day key (yyyy-mm-dd) -> steps counted by this phone's step sensor.
  final Map<String, int> _history = {};

  /// Day key -> steps from Health Connect (Samsung Health, Google Fit, ...).
  /// Those apps count in the background all day, so for each day we show
  /// whichever source saw more steps.
  final Map<String, int> _healthHistory = {};
  bool _healthConnected = false;
  DateTime? _healthSyncedAt;
  Timer? _healthTimer;

  bool _permissionDenied = false;

  /// Last raw hardware counter value seen and the day it was seen on.
  /// Steps are accumulated as deltas between readings, so a reboot (counter
  /// reset) or a new day never pulls in steps from another day.
  int? _lastRaw;
  String _lastDate = '';

  StreamSubscription<StepCount>? _stepSub;
  SharedPreferences? _prefs;

  Gender get gender => _gender ?? Gender.male;
  bool get genderChosen => _gender != null;
  int get _sensorToday => _lastDate == todayKey() ? _todaySteps : 0;
  int get todaySteps => math.max(_sensorToday, _healthHistory[todayKey()] ?? 0);
  bool get healthConnected => _healthConnected;
  DateTime? get healthSyncedAt => _healthSyncedAt;
  int get goal => _goal;
  int get coins => _coins;
  bool get permissionDenied => _permissionDenied;
  Set<String> get owned => _owned;
  String get outfitId => _outfit;
  Map<String, int> get history {
    final h = Map<String, int>.from(_history);
    _healthHistory.forEach((day, steps) {
      if (steps > (h[day] ?? 0)) h[day] = steps;
    });
    h[todayKey()] = todaySteps;
    return h;
  }

  double get progress => _goal <= 0 ? 0 : (todaySteps / _goal).clamp(0.0, 1.0);

  /// 1.0 = fully chubby (no progress), 0.15 = slimmest.
  double get chubbiness => (1.0 - progress * 0.85).clamp(0.15, 1.0);

  Future<void> init() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    final g = prefs.getString('gender');
    _gender = Gender.values.where((v) => v.name == g).firstOrNull;
    _goal = prefs.getInt('goal') ?? kDefaultGoal;
    _coins = prefs.getInt('coins') ?? 0;

    _owned.addAll(prefs.getStringList('owned_outfits') ?? const []);
    final outfit = prefs.getString('outfit');
    if (outfit != null && _owned.contains(outfit)) _outfit = outfit;

    final rawHistory = prefs.getString('history');
    if (rawHistory != null) {
      final decoded = jsonDecode(rawHistory) as Map<String, dynamic>;
      decoded.forEach((k, v) => _history[k] = (v as num).toInt());
    }

    _lastRaw = prefs.getInt('last_raw');
    _lastDate = prefs.getString('last_date') ??
        prefs.getString('baseline_date') ??
        '';
    _todaySteps = prefs.getInt('today_steps') ?? 0;

    final rawHealth = prefs.getString('health_history');
    if (rawHealth != null) {
      (jsonDecode(rawHealth) as Map<String, dynamic>)
          .forEach((k, v) => _healthHistory[k] = (v as num).toInt());
    }
    _healthConnected = prefs.getBool('health_connected') ?? false;

    notifyListeners();
  }

  // ---- Health Connect (Samsung Health) -------------------------------------

  /// Connects to Health Connect. Returns null on success, otherwise a
  /// Mongolian message explaining what's missing.
  Future<String?> connectHealth() async {
    final status = await HealthConnect.status();
    if (status == HealthConnectStatus.needsInstall) {
      await HealthConnect.openInstall();
      return 'Health Connect-ийг суулгаж (эсвэл шинэчилж) дуусаад дахин оролдоно уу.';
    }
    if (status == HealthConnectStatus.unavailable) {
      return 'Энэ утсанд Health Connect ажиллахгүй байна.';
    }
    final granted = await HealthConnect.hasPermission() || await HealthConnect.requestPermission();
    if (!granted) {
      return 'Алхамын мэдээлэл унших зөвшөөрөл өгөөгүй байна.';
    }
    _healthConnected = true;
    await _prefs?.setBool('health_connected', true);
    notifyListeners();
    await refreshHealth();
    _startHealthTimer();
    return null;
  }

  Future<void> disconnectHealth() async {
    _healthConnected = false;
    _healthHistory.clear();
    _healthSyncedAt = null;
    _healthTimer?.cancel();
    _healthTimer = null;
    await _prefs?.setBool('health_connected', false);
    await _prefs?.remove('health_history');
    notifyListeners();
  }

  /// Pulls the last 35 days of step totals from Health Connect.
  Future<void> refreshHealth() async {
    if (!_healthConnected) return;
    // Health Connect only serves reads to the app on screen.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    if (!await HealthConnect.hasPermission()) {
      // Permission was revoked in Health Connect's settings.
      await disconnectHealth();
      return;
    }
    try {
      final days = await HealthConnect.dailySteps(35);
      _healthHistory
        ..clear()
        ..addAll(days);
      _healthSyncedAt = DateTime.now();
      await _prefs?.setString('health_history', jsonEncode(_healthHistory));
      notifyListeners();
    } on PlatformException {
      // Try again on the next refresh.
    }
  }

  void _startHealthTimer() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(minutes: 2), (_) => refreshHealth());
  }

  /// Asks for the activity permission (if needed) and starts counting.
  /// Safe to call again, e.g. after the user grants it in system settings.
  Future<void> startTracking() async {
    try {
      final status = await Permission.activityRecognition.request();
      _permissionDenied = !status.isGranted;
      notifyListeners();
      if (_permissionDenied) return;

      await _stepSub?.cancel();
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (Object _) {},
        cancelOnError: false,
      );
    } on MissingPluginException {
      // No step sensor plugin on this platform (e.g. widget tests).
    }
    if (_healthConnected) {
      await refreshHealth();
      _startHealthTimer();
    }
  }

  void _onStepCount(StepCount event) {
    final raw = event.steps;
    final today = todayKey();
    final last = _lastRaw;

    if (_lastDate != today) {
      _todaySteps = 0;
      _lastDate = today;
    } else if (last != null) {
      // A lower value than last time means the phone rebooted and the
      // hardware counter restarted from 0.
      _todaySteps += raw >= last ? raw - last : raw;
    }
    _lastRaw = raw;
    _history[today] = _todaySteps;
    _trimHistory();

    final prefs = _prefs;
    if (prefs != null) {
      prefs.setInt('last_raw', raw);
      prefs.setString('last_date', _lastDate);
      prefs.setInt('today_steps', _todaySteps);
      prefs.setString('history', jsonEncode(_history));
    }
    notifyListeners();
  }

  void _trimHistory() {
    if (_history.length <= _kHistoryDaysKept) return;
    final keys = _history.keys.toList()..sort();
    for (final k in keys.take(keys.length - _kHistoryDaysKept)) {
      _history.remove(k);
    }
  }

  Future<void> setGender(Gender g) async {
    _gender = g;
    await _prefs?.setString('gender', g.name);
    notifyListeners();
  }

  Future<void> setGoal(int newGoal) async {
    if (newGoal <= 0) return;
    _goal = newGoal;
    await _prefs?.setInt('goal', _goal);
    notifyListeners();
  }

  Future<void> addCoinsFromAd() async {
    _coins += kCoinsPerAdWatch;
    await _prefs?.setInt('coins', _coins);
    notifyListeners();
  }

  bool buyOutfit(Outfit outfit) {
    if (_owned.contains(outfit.id) || _coins < outfit.price) return false;
    _coins -= outfit.price;
    _owned.add(outfit.id);
    _prefs?.setInt('coins', _coins);
    _prefs?.setStringList('owned_outfits', _owned.toList());
    // Put it on right away so the purchase is visible.
    wearOutfit(outfit);
    return true;
  }

  void wearOutfit(Outfit outfit) {
    if (!_owned.contains(outfit.id)) return;
    _outfit = outfit.id;
    _prefs?.setString('outfit', outfit.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _healthTimer?.cancel();
    super.dispose();
  }
}
