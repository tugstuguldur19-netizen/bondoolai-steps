import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clothing_item.dart';

const int kDefaultGoal = 10000;
const int kCoinsPerAdWatch = 25;

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class GameState extends ChangeNotifier {
  int _todaySteps = 0;
  int _goal = kDefaultGoal;
  int _coins = 0;
  final Set<String> _owned = {};
  final Map<ClothingSlot, String?> _equipped = {
    ClothingSlot.hat: null,
    ClothingSlot.top: null,
    ClothingSlot.bottom: null,
    ClothingSlot.shoes: null,
    ClothingSlot.glasses: null,
  };

  bool _permissionDenied = false;
  String? _pedometerError;

  int _baselineSteps = 0;
  String _baselineDate = '';

  StreamSubscription<StepCount>? _stepSub;
  late SharedPreferences _prefs;

  int get todaySteps => _todaySteps;
  int get goal => _goal;
  int get coins => _coins;
  bool get permissionDenied => _permissionDenied;
  String? get pedometerError => _pedometerError;
  Set<String> get owned => _owned;
  Map<ClothingSlot, String?> get equipped => _equipped;

  double get progress => _goal <= 0 ? 0 : (_todaySteps / _goal).clamp(0.0, 1.0);

  /// 1.0 = fully chubby (no progress), floor of 0.15 = slimmest.
  double get chubbiness => (1.0 - progress * 0.85).clamp(0.15, 1.0);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _goal = _prefs.getInt('goal') ?? kDefaultGoal;
    _coins = _prefs.getInt('coins') ?? 0;
    _owned.addAll(_prefs.getStringList('owned') ?? const []);
    for (final slot in ClothingSlot.values) {
      final id = _prefs.getString('equipped_${slot.name}');
      if (id != null && _owned.contains(id)) {
        _equipped[slot] = id;
      }
    }
    _baselineSteps = _prefs.getInt('baseline_steps') ?? 0;
    _baselineDate = _prefs.getString('baseline_date') ?? '';
    _todaySteps = _prefs.getInt('today_steps') ?? 0;

    final today = _todayKey();
    if (_baselineDate != today) {
      // New day: today's steps restart at 0, baseline gets set on first
      // sensor reading below.
      _baselineDate = today;
      _todaySteps = 0;
      await _prefs.setString('baseline_date', _baselineDate);
      await _prefs.setInt('today_steps', 0);
    }
    notifyListeners();

    await _startPedometer();
  }

  Future<void> _startPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      _permissionDenied = true;
      notifyListeners();
      return;
    }
    _permissionDenied = false;

    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error) {
        _pedometerError = error.toString();
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  void _onStepCount(StepCount event) {
    final raw = event.steps;
    final today = _todayKey();

    if (_baselineDate != today) {
      // Rolled over to a new day since last reading.
      _baselineDate = today;
      _baselineSteps = raw;
    } else if (raw < _baselineSteps) {
      // Device rebooted; the hardware counter reset to a lower value.
      _baselineSteps = raw;
    } else if (_todaySteps == 0 && _baselineSteps == 0) {
      // First ever reading for a fresh install/day.
      _baselineSteps = raw;
    }

    _todaySteps = raw - _baselineSteps;
    if (_todaySteps < 0) _todaySteps = 0;

    _prefs.setInt('baseline_steps', _baselineSteps);
    _prefs.setString('baseline_date', _baselineDate);
    _prefs.setInt('today_steps', _todaySteps);

    notifyListeners();
  }

  Future<void> setGoal(int newGoal) async {
    if (newGoal <= 0) return;
    _goal = newGoal;
    await _prefs.setInt('goal', _goal);
    notifyListeners();
  }

  Future<void> addCoinsFromAd() async {
    _coins += kCoinsPerAdWatch;
    await _prefs.setInt('coins', _coins);
    notifyListeners();
  }

  bool buyItem(ClothingItem item) {
    if (_owned.contains(item.id) || _coins < item.price) return false;
    _coins -= item.price;
    _owned.add(item.id);
    _prefs.setInt('coins', _coins);
    _prefs.setStringList('owned', _owned.toList());
    notifyListeners();
    return true;
  }

  void toggleEquip(ClothingItem item) {
    if (!_owned.contains(item.id)) return;
    if (_equipped[item.slot] == item.id) {
      _equipped[item.slot] = null;
      _prefs.remove('equipped_${item.slot.name}');
    } else {
      _equipped[item.slot] = item.id;
      _prefs.setString('equipped_${item.slot.name}', item.id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }
}
