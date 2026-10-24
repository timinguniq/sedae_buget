import 'dart:convert';

import 'package:sedae_budget/core/util/logger/custom_logger.dart';

final _logger = CustomLogger.create(tag: 'StubApiState');

typedef _Json = Map<String, dynamic>;

/// Stub 서버가 보관하는 상태. 사용자(로그인 provider 이름)마다 따로 둔다 — 계약상 데이터는 사용자 것이다.
///
/// 기기에 저장하는 형식은 [encode]·[decode]만 안다. 형식에는 [version]을 적는다. 읽을 때는 던지지 않는다:
/// 못 읽는 사용자·프로필·거래·사용자 카테고리·토큰은 그것만 버리고(로그를 남긴다) 나머지는 살린다.
/// 형식이 한 번 어긋났다고 모든 요청이 500이 되어 앱이 '연결 안 됨'에 갇히지 않게.
class StubApiState {
  /// 저장 형식 버전. 형식을 바꾸면 올리고 [decode]에서 이전 버전을 옮긴다.
  static const version = 1;

  final Map<String, StubUserData> _users = {};

  /// 로그인으로 준 토큰 중 로그아웃하지 않은 것. 이 밖의 토큰은 401이다.
  final Set<String> activeTokens = {};

  /// [user]의 데이터. 처음 보는 사용자면 빈 데이터를 만든다.
  StubUserData of(String user) => _users.putIfAbsent(user, StubUserData.new);

  /// 기기에 저장할 문자열.
  String encode() => jsonEncode({
        'version': version,
        'users': {for (final e in _users.entries) e.key: e.value.toJson()},
        'activeTokens': activeTokens.toList(),
      });

  /// 기기에 저장된 [raw]로 바꾼다. 던지지 않는다.
  ///
  /// 버전이 없고 `users`가 있으면 버전 1이다(버전을 적기 전에 저장한 형식). 사용자별로 나누기 전 형식
  /// (`users`가 없음)과 모르는 버전은 읽지 않고 빈 상태로 시작한다.
  void decode(String raw) {
    _users.clear();
    activeTokens.clear();
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException catch (e) {
      return _drop('JSON이 아니어서 빈 상태로 시작해요: $e');
    }
    if (json is! _Json) return _drop('객체가 아니어서 빈 상태로 시작해요');
    final v = json['version'] ?? (json.containsKey('users') ? 1 : null);
    if (v == null) return _drop('사용자별로 나누기 전 형식이라 빈 상태로 시작해요');
    if (v != version) return _drop('모르는 형식(version $v)이라 빈 상태로 시작해요');

    final tokens = json['activeTokens'];
    final readable = tokens is List ? tokens.whereType<String>() : const <String>[];
    activeTokens.addAll(readable);
    if (tokens != null && (tokens is! List || readable.length != tokens.length)) _drop('읽지 못한 토큰을 버려요');

    final users = json['users'];
    if (users is! _Json) return _drop('사용자 데이터를 읽지 못해 버려요');
    users.forEach((user, data) {
      if (data is _Json) {
        _users[user] = StubUserData()..loadFrom(data);
      } else {
        _drop('사용자 $user의 데이터를 읽지 못해 버려요');
      }
    });
  }
}

/// 한 사용자의 데이터. 프로필 1개 + 거래 id→JSON + 사용자 카테고리 id→JSON(생성 순서 유지).
class StubUserData {
  Map<String, dynamic>? profile;
  final Map<String, Map<String, dynamic>> transactions = {};
  final Map<String, Map<String, dynamic>> customCategories = {};

  Map<String, dynamic> toJson() => {
        'profile': profile,
        'transactions': transactions,
        'customCategories': customCategories,
      };

  /// [json]으로 바꾼다. 던지지 않는다: 못 읽는 프로필·행은 버린다. 행은 Stub이 읽는 값
  /// (거래의 `date`, 사용자 카테고리의 `name`)을 읽을 수 있어야 한다. 그 밖의 값만 어긋난 행은 남고,
  /// 앱이 그 행을 해석하지 못하면 그 화면의 불러오기 실패(다시 시도)로 보인다.
  void loadFrom(Map<String, dynamic> json) {
    final p = json['profile'];
    profile = p is _Json ? p : null;
    if (p != null && profile == null) _drop('읽지 못한 프로필을 버려요');
    transactions
      ..clear()
      ..addAll(_rows('거래', json['transactions'], (r) {
        final date = r['date'];
        return date is String && DateTime.tryParse(date) != null;
      }));
    customCategories
      ..clear()
      ..addAll(_rows('사용자 카테고리', json['customCategories'], (r) => r['name'] is String));
  }

  Map<String, Map<String, dynamic>> _rows(String what, Object? raw, bool Function(_Json) readable) {
    if (raw == null) return {};
    if (raw is! _Json) {
      _drop('$what 목록을 읽지 못해 버려요');
      return {};
    }
    final rows = <String, Map<String, dynamic>>{};
    raw.forEach((id, row) {
      if (row is _Json && readable(row)) {
        rows[id] = row;
      } else {
        _drop('읽지 못한 $what $id를 버려요');
      }
    });
    return rows;
  }
}

void _drop(String message) => _logger.w('저장된 Stub 상태: $message');
