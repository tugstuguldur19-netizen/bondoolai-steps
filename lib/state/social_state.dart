import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'app_state.dart';

enum LeaderboardPeriod { day, week, month }

extension LeaderboardPeriodInfo on LeaderboardPeriod {
  String get label {
    switch (this) {
      case LeaderboardPeriod.day:
        return 'Өнөөдөр';
      case LeaderboardPeriod.week:
        return '7 хоног';
      case LeaderboardPeriod.month:
        return '30 хоног';
    }
  }

  /// Rolling window length in days, including today.
  int get days {
    switch (this) {
      case LeaderboardPeriod.day:
        return 1;
      case LeaderboardPeriod.week:
        return 7;
      case LeaderboardPeriod.month:
        return 30;
    }
  }
}

class LeaderboardEntry {
  final String userId;
  final String name;
  final int steps;
  final bool isMe;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.steps,
    required this.isMe,
  });
}

class SocialException implements Exception {
  final String message;
  const SocialException(this.message);

  @override
  String toString() => message;
}

const _networkError = SocialException('Интернэт холболтоо шалгаад дахин оролдоно уу.');
const _serverError = SocialException('Сервертэй холбогдоход алдаа гарлаа. Дахин оролдоно уу.');
const _syncInterval = Duration(minutes: 3);

class SocialState extends ChangeNotifier {
  SocialState(this._game) {
    _game.addListener(_onGameChanged);
  }

  final GameState _game;
  final http.Client _client = http.Client();
  SharedPreferences? _prefs;

  String? _userId;
  String? _accessToken;
  String? _refreshToken;
  int _expiresAt = 0;

  String? _name;
  String? _friendCode;

  bool _busy = false;
  String? _error;
  final Map<LeaderboardPeriod, List<LeaderboardEntry>> _boards = {};

  DateTime? _lastSync;
  Timer? _syncTimer;

  bool get configured => socialConfigured;
  bool get hasProfile => _name != null && _friendCode != null;
  String? get name => _name;
  String? get friendCode => _friendCode;
  bool get busy => _busy;
  String? get error => _error;
  List<LeaderboardEntry>? board(LeaderboardPeriod p) => _boards[p];

  String get inviteText =>
      'Бондоолой апп дээр надтай хамт алхаж өрсөлдөөрэй! '
      'Миний найзын код: ${_friendCode ?? ''}\n'
      'Апп татах: $appDownloadUrl';

  Future<void> init() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('sb_user_id');
    _accessToken = prefs.getString('sb_access');
    _refreshToken = prefs.getString('sb_refresh');
    _expiresAt = prefs.getInt('sb_expires_at') ?? 0;
    _name = prefs.getString('sb_name');
    _friendCode = prefs.getString('sb_code');
    notifyListeners();
    if (configured && hasProfile) {
      unawaited(refreshLeaderboards());
    }
  }

  // ---- HTTP plumbing -------------------------------------------------------

  Uri _uri(String path) => Uri.parse('$supabaseUrl$path');

  Map<String, String> _headers({String? prefer, bool withAuth = true}) => {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
        if (withAuth && _accessToken != null) 'Authorization': 'Bearer $_accessToken',
        if (prefer != null) 'Prefer': prefer,
      };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw _networkError;
    } on http.ClientException {
      throw _networkError;
    } catch (e) {
      if (e is SocialException) rethrow;
      // SocketException and friends (dart:io isn't imported to keep this
      // file testable on any platform).
      throw _networkError;
    }
  }

  Future<http.Response> _post(String path, Object body, {String? prefer, bool withAuth = true}) =>
      _send(() => _client.post(
            _uri(path),
            headers: _headers(prefer: prefer, withAuth: withAuth),
            body: jsonEncode(body),
          ));

  String _errorMessage(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map) {
        return (body['message'] ?? body['msg'] ?? body['error_description'] ?? body['error'] ?? '')
            .toString();
      }
    } catch (_) {}
    return '';
  }

  // ---- Auth ----------------------------------------------------------------

  Future<void> _saveSession(Map<String, dynamic> json) async {
    _accessToken = json['access_token'] as String?;
    _refreshToken = json['refresh_token'] as String?;
    final user = json['user'] as Map<String, dynamic>?;
    _userId = (user?['id'] as String?) ?? _userId;
    final expiresAt = json['expires_at'] as int?;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    _expiresAt = expiresAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString('sb_user_id', _userId ?? '');
      await prefs.setString('sb_access', _accessToken ?? '');
      await prefs.setString('sb_refresh', _refreshToken ?? '');
      await prefs.setInt('sb_expires_at', _expiresAt);
    }
  }

  Future<void> _ensureSession() async {
    if (!configured) {
      throw const SocialException('Найзуудын сервер тохируулагдаагүй байна.');
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_accessToken != null && _accessToken!.isNotEmpty && now < _expiresAt - 60) return;

    final refresh = _refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      final r = await _post(
        '/auth/v1/token?grant_type=refresh_token',
        {'refresh_token': refresh},
        withAuth: false,
      );
      if (r.statusCode == 200) {
        await _saveSession(jsonDecode(r.body) as Map<String, dynamic>);
        return;
      }
      if (r.statusCode >= 500) throw _serverError;
      // The refresh token is no longer valid: this device has to start a new
      // anonymous account. Keep the display name so we can recreate it.
    }

    final r = await _post('/auth/v1/signup', {'data': <String, dynamic>{}}, withAuth: false);
    if (r.statusCode != 200) {
      final msg = _errorMessage(r).toLowerCase();
      if (msg.contains('anonymous')) {
        throw const SocialException('Сервер дээр нэргүй нэвтрэлт (anonymous sign-in) идэвхжээгүй байна.');
      }
      throw _serverError;
    }
    final hadProfile = hasProfile;
    await _saveSession(jsonDecode(r.body) as Map<String, dynamic>);
    if (hadProfile) {
      // New account: the old profile row belongs to the old account.
      final keepName = _name!;
      _friendCode = null;
      await _createProfileRow(keepName);
    }
  }

  // ---- Profile -------------------------------------------------------------

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _newCode() {
    final rnd = Random.secure();
    return List.generate(6, (_) => _codeChars[rnd.nextInt(_codeChars.length)]).join();
  }

  Future<void> _createProfileRow(String name) async {
    final existing = await _send(() => _client.get(
          _uri('/rest/v1/profiles?id=eq.$_userId&select=name,friend_code'),
          headers: _headers(),
        ));
    if (existing.statusCode == 200) {
      final rows = jsonDecode(existing.body) as List<dynamic>;
      if (rows.isNotEmpty) {
        _friendCode = (rows.first as Map<String, dynamic>)['friend_code'] as String;
        await _patchName(name);
        return;
      }
    }

    for (var attempt = 0; attempt < 6; attempt++) {
      final code = _newCode();
      final r = await _post(
        '/rest/v1/profiles',
        {'id': _userId, 'name': name, 'friend_code': code},
        prefer: 'return=minimal',
      );
      if (r.statusCode == 201 || r.statusCode == 204) {
        await _saveProfile(name, code);
        return;
      }
      if (r.statusCode != 409) throw _serverError;
    }
    throw _serverError;
  }

  Future<void> _patchName(String name) async {
    final r = await _send(() => _client.patch(
          _uri('/rest/v1/profiles?id=eq.$_userId'),
          headers: _headers(prefer: 'return=minimal'),
          body: jsonEncode({'name': name}),
        ));
    if (r.statusCode != 204 && r.statusCode != 200) throw _serverError;
    await _saveProfile(name, _friendCode!);
  }

  Future<void> _saveProfile(String name, String code) async {
    _name = name;
    _friendCode = code;
    await _prefs?.setString('sb_name', name);
    await _prefs?.setString('sb_code', code);
  }

  /// Creates this device's profile, or renames it if it already exists.
  Future<void> saveName(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) throw const SocialException('Нэрээ оруулна уу.');
    if (name.length > 30) throw const SocialException('Нэр 30 тэмдэгтээс ихгүй байна.');
    _setBusy(true);
    try {
      await _ensureSession();
      if (hasProfile) {
        await _patchName(name);
      } else {
        await _createProfileRow(name);
      }
      _error = null;
    } finally {
      _setBusy(false);
    }
    unawaited(refreshLeaderboards());
  }

  // ---- Friends -------------------------------------------------------------

  /// Returns the new friend's display name.
  Future<String> addFriend(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != 6) throw const SocialException('Найзын код 6 тэмдэгттэй байна.');
    if (code == _friendCode) throw const SocialException('Өөрийгөө найзаар нэмэх боломжгүй.');
    await _ensureSession();
    final r = await _post('/rest/v1/rpc/add_friend', {'code': code});
    if (r.statusCode != 200) {
      final msg = _errorMessage(r);
      if (msg.contains('not_found')) throw const SocialException('Ийм кодтой хэрэглэгч олдсонгүй.');
      if (msg.contains('self')) throw const SocialException('Өөрийгөө найзаар нэмэх боломжгүй.');
      throw _serverError;
    }
    final friend = jsonDecode(r.body) as Map<String, dynamic>;
    unawaited(refreshLeaderboards());
    return friend['name'] as String;
  }

  // ---- Steps + leaderboards -----------------------------------------------

  Future<void> _syncSteps() async {
    await _ensureSession();
    final cutoff = dayKey(DateTime.now().subtract(const Duration(days: 35)));
    final today = todayKey();
    final rows = _game.history.entries
        .where((e) => e.key.compareTo(cutoff) >= 0 && (e.value > 0 || e.key == today))
        .map((e) => {'user_id': _userId, 'day': e.key, 'steps': e.value})
        .toList();
    if (rows.isEmpty) return;
    final r = await _post(
      '/rest/v1/daily_steps?on_conflict=user_id,day',
      rows,
      prefer: 'resolution=merge-duplicates,return=minimal',
    );
    if (r.statusCode >= 300) throw _serverError;
    _lastSync = DateTime.now();
  }

  Future<List<LeaderboardEntry>> _loadBoard(LeaderboardPeriod period) async {
    final since = dayKey(DateTime.now().subtract(Duration(days: period.days - 1)));
    final r = await _post('/rest/v1/rpc/leaderboard', {'since': since});
    if (r.statusCode != 200) throw _serverError;
    final rows = jsonDecode(r.body) as List<dynamic>;
    return rows.map((row) {
      final m = row as Map<String, dynamic>;
      final id = m['user_id'] as String;
      return LeaderboardEntry(
        userId: id,
        name: m['name'] as String,
        steps: (m['steps'] as num).toInt(),
        isMe: id == _userId,
      );
    }).toList();
  }

  Future<void> refreshLeaderboards() async {
    if (!configured || !hasProfile || _busy) return;
    _setBusy(true);
    try {
      await _syncSteps();
      for (final p in LeaderboardPeriod.values) {
        _boards[p] = await _loadBoard(p);
      }
      _error = null;
    } on SocialException catch (e) {
      _error = e.message;
    } finally {
      _setBusy(false);
    }
  }

  void _onGameChanged() {
    if (!configured || !hasProfile) return;
    final last = _lastSync;
    if (last == null || DateTime.now().difference(last) >= _syncInterval) {
      _lastSync = DateTime.now();
      _syncSteps().catchError((_) {});
      return;
    }
    _syncTimer ??= Timer(_syncInterval - DateTime.now().difference(last), () {
      _syncTimer = null;
      _onGameChanged();
    });
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _syncTimer?.cancel();
    _client.close();
    super.dispose();
  }
}
