import 'package:flutter/services.dart';

/// Bridge to the native background step counter (StepCounterService.kt),
/// which counts all day and keeps per-day totals even while the app is
/// closed or after a reboot.
class StepService {
  static const _channel = MethodChannel('bondoolai/steps');

  static Future<void> start({required int goal, required int seedToday}) =>
      _call('start', {'goal': goal, 'seedToday': seedToday});

  static Future<void> setGoal(int goal) => _call('setGoal', {'goal': goal});

  /// Steps per day ("yyyy-mm-dd" -> steps) recorded by the service.
  static Future<Map<String, int>> snapshot() async {
    try {
      return await _channel.invokeMapMethod<String, int>('snapshot') ?? const {};
    } on MissingPluginException {
      return const {};
    } on PlatformException {
      return const {};
    }
  }

  static Future<void> _call(String method, Map<String, Object> args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Not Android (e.g. widget tests).
    } on PlatformException {
      // Service unavailable right now; the next app start retries.
    }
  }
}
