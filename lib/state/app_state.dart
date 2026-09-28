import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/items.dart';
import '../services/health_connect.dart';
import '../services/step_service.dart';

enum Gender { male, female }

const int kDefaultGoal = 10000;
const int kCoinsPerAdWatch = 25;
const int _kHistoryDaysKept = 400;

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayKey() => dayKey(DateTime.now());

class GameState extends ChangeNotifier {
  Gender? _gender;
  int _goal = kDefaultGoal;
  int _coins = 0;
  final Set<String> _owned = {};
  final Map<ItemSlot, String> _equipped = {};

  /// Day key (yyyy-mm-dd) -> steps counted by this phone's step sensor
  /// (recorded by the native background service, StepCounterService.kt).
  final Map<String, int> _history = {};
  Timer? _pollTimer;

  /// Day key -> steps from Health Connect (Samsung Health, Google Fit, ...).
  /// Those apps count in the background all day, so for each day we show
  /// whichever source saw more steps.
  final Map<String, int> _healthHistory = {};
  bool _healthConnected = false;
  DateTime? _healthSyncedAt;
  Timer? _healthTimer;

  bool _permissionDenied = false;
  SharedPreferences? _prefs;

  Gender get gender => _gender ?? Gender.male;
  bool get genderChosen => _gender != null;
  int get _sensorToday => _history[todayKey()] ?? 0;
  int get todaySteps => math.max(_sensorToday, _healthHistory[todayKey()] ?? 0);
  bool get healthConnected => _healthConnected;
  DateTime? get healthSyncedAt => _healthSyncedAt;
  int get goal => _goal;
  int get coins => _coins;
  bool get permissionDenied => _permissionDenied;
  Set<String> get owned => _owned;
  Map<ItemSlot, String> get equipped => Map.unmodifiable(_equipped);
  Map<String, int> get history {
    final h = Map<String, int>.from(_history);
    _healthHistory.forEach((day, steps) {
      if (steps > (h[day] ?? 0)) h[day] = steps;
    });
    h[todayKey()] = todaySteps;
    return h;
  }

  double get progress => _goal <= 0 ? 0 : (todaySteps / _goal).clamp(0.0, 1.0);

  /// Body level at the start of the day: 6 (obese) for goals of 10,000 or
  /// more, 5 (overweight) for smaller goals.
  int get startLevel => _goal >= 10000 ? 6 : 5;

  /// Current body level: 1 = fit. Walking toward the goal steps it down
  /// evenly from [startLevel]; reaching the goal gives level 1.
  int get level {
    final s = startLevel;
    return (s - (progress * (s - 1)).floor()).clamp(1, s);
  }

  /// Steps still needed today to reach the next (leaner) level, or null at
  /// level 1.
  int? get stepsToNextLevel {
    final l = level;
    if (l <= 1) return null;
    final s = startLevel;
    final needed = ((s - (l - 1)) / (s - 1) * _goal).ceil();
    return math.max(0, needed - todaySteps);
  }

  Future<void> init() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    final g = prefs.getString('gender');
    _gender = Gender.values.where((v) => v.name == g).firstOrNull;
    _goal = prefs.getInt('goal') ?? kDefaultGoal;
    _coins = prefs.getInt('coins') ?? 0;

    await _migrateOutfits(prefs);
    _owned.addAll((prefs.getStringList('owned_items') ?? const []).where((id) => itemById(id) != null));
    for (final slot in ItemSlot.values) {
      final id = prefs.getString('wear_${slot.name}');
      if (id != null && _owned.contains(id)) _equipped[slot] = id;
    }

    final rawHistory = prefs.getString('history');
    if (rawHistory != null) {
      final decoded = jsonDecode(rawHistory) as Map<String, dynamic>;
      decoded.forEach((k, v) => _history[k] = (v as num).toInt());
    }

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

  /// Asks for the needed permissions and starts the background step
  /// counter. Safe to call again, e.g. after the user grants a permission in
  /// system settings.
  Future<void> startTracking() async {
    try {
      final status = await Permission.activityRecognition.request();
      _permissionDenied = !status.isGranted;
      notifyListeners();
      if (!_permissionDenied) {
        // Android 13+: needed to show the ongoing "today's steps" notification.
        await Permission.notification.request();
        await StepService.start(goal: _goal, seedToday: _sensorToday);
        await syncSteps();
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => syncSteps());
      }
    } on MissingPluginException {
      // No permission plugin on this platform (e.g. widget tests).
    }
    if (_healthConnected) {
      await refreshHealth();
      _startHealthTimer();
    }
  }

  /// Pulls the per-day totals the background service has recorded.
  Future<void> syncSteps() async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final days = await StepService.snapshot();
    var changed = false;
    days.forEach((day, steps) {
      if (steps > (_history[day] ?? 0)) {
        _history[day] = steps;
        changed = true;
      }
    });
    if (!changed) return;
    _trimHistory();
    await _prefs?.setString('history', jsonEncode(_history));
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
    await StepService.setGoal(_goal);
    notifyListeners();
  }

  Future<void> addCoinsFromAd() async {
    _coins += kCoinsPerAdWatch;
    await _prefs?.setInt('coins', _coins);
    notifyListeners();
  }

  /// One-time conversion of outfits bought in earlier versions into the
  /// matching deels.
  Future<void> _migrateOutfits(SharedPreferences prefs) async {
    final oldOwned = prefs.getStringList('owned_outfits');
    if (oldOwned != null) {
      final owned = {...?prefs.getStringList('owned_items')};
      for (final old in oldOwned) {
        final id = legacyOutfitIds[old];
        if (id != null) owned.add(id);
      }
      await prefs.setStringList('owned_items', owned.toList());
      await prefs.remove('owned_outfits');
    }
    final oldWorn = legacyOutfitIds[prefs.getString('outfit')];
    if (oldWorn != null) await prefs.setString('wear_${ItemSlot.deel.name}', oldWorn);
    await prefs.remove('outfit');
  }

  bool buy(ShopItem item) {
    if (_owned.contains(item.id) || _coins < item.price) return false;
    _coins -= item.price;
    _owned.add(item.id);
    _prefs?.setInt('coins', _coins);
    _prefs?.setStringList('owned_items', _owned.toList());
    // Put it on right away so the purchase is visible.
    if (!isWearing(item)) toggleWear(item);
    return true;
  }

  bool isWearing(ShopItem item) => _equipped[item.slot] == item.id;

  /// Puts an owned item on, or takes it off if it's already worn.
  void toggleWear(ShopItem item) {
    if (!_owned.contains(item.id)) return;
    if (isWearing(item)) {
      _equipped.remove(item.slot);
      _prefs?.remove('wear_${item.slot.name}');
    } else {
      _equipped[item.slot] = item.id;
      _prefs?.setString('wear_${item.slot.name}', item.id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _healthTimer?.cancel();
    super.dispose();
  }
}
