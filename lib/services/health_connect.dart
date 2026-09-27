import 'package:flutter/services.dart';

enum HealthConnectStatus { available, needsInstall, unavailable }

/// Reads step totals from Android Health Connect, which Samsung Health (and
/// Google Fit, etc.) write to. Native side: MainActivity.kt.
class HealthConnect {
  static const _channel = MethodChannel('bondoolai/health');

  static Future<HealthConnectStatus> status() async {
    try {
      final s = await _channel.invokeMethod<String>('status');
      switch (s) {
        case 'available':
          return HealthConnectStatus.available;
        case 'needs_install':
          return HealthConnectStatus.needsInstall;
      }
    } on MissingPluginException {
      // Not Android (e.g. tests).
    } on PlatformException {
      // Fall through.
    }
    return HealthConnectStatus.unavailable;
  }

  static Future<bool> hasPermission() => _bool('hasPermission');

  static Future<bool> requestPermission() => _bool('requestPermission');

  static Future<void> openInstall() async {
    try {
      await _channel.invokeMethod<void>('openInstall');
    } on MissingPluginException {
      // Nothing to open.
    }
  }

  /// Steps per day ("yyyy-mm-dd" -> steps) for the last [days] days.
  static Future<Map<String, int>> dailySteps(int days) async {
    final raw = await _channel.invokeMapMethod<String, int>('dailySteps', {'days': days});
    return raw ?? const {};
  }

  static Future<bool> _bool(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
