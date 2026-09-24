import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clothing_item.dart';

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
  final Set<String> _owned = {};
  final Map<ClothingSlot, String?> _equipped = {
    for (final slot in ClothingSlot.values) slot: null,
  };

  /// Day key (yyyy-mm-dd) -> steps walked that day.
  final Map<String, int> _history = {};

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
  int get todaySteps => _lastDate == todayKey() ? _todaySteps : 0;
  int get goal => _goal;
  int get coins => _coins;
  bool get permissionDenied => _permissionDenied;
  Set<String> get owned => _owned;
  Map<ClothingSlot, String?> get equipped => _equipped;
  Map<String, int> get history {
    final h = Map<String, int>.from(_history);
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

    // Items from older catalogs no longer exist; drop them.
    _owned.addAll(
      (prefs.getStringList('owned') ?? const []).where((id) => itemById(id) != null),
    );
    for (final slot in ClothingSlot.values) {
      final id = prefs.getString('equipped_${slot.name}');
      if (id != null && _owned.contains(id) && itemById(id)?.slot == slot) {
        _equipped[slot] = id;
      }
    }

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

    notifyListeners();
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

  bool buyItem(ClothingItem item) {
    if (_owned.contains(item.id) || _coins < item.price) return false;
    _coins -= item.price;
    _owned.add(item.id);
    _prefs?.setInt('coins', _coins);
    _prefs?.setStringList('owned', _owned.toList());
    // Put it on right away so the purchase is visible.
    _equipped[item.slot] = item.id;
    _prefs?.setString('equipped_${item.slot.name}', item.id);
    notifyListeners();
    return true;
  }

  void toggleEquip(ClothingItem item) {
    if (!_owned.contains(item.id)) return;
    if (_equipped[item.slot] == item.id) {
      _equipped[item.slot] = null;
      _prefs?.remove('equipped_${item.slot.name}');
    } else {
      _equipped[item.slot] = item.id;
      _prefs?.setString('equipped_${item.slot.name}', item.id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }
}
