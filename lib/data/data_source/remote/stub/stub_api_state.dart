/// Stub 서버의 "DB". 사용자(로그인 provider 이름)마다 따로 둔다 — 계약상 데이터는 사용자 것이다.
class StubApiState {
  final Map<String, StubUserData> _users = {};

  /// 로그인으로 준 토큰 중 로그아웃하지 않은 것. 이 밖의 토큰은 401이다.
  final Set<String> activeTokens = {};

  /// [user]의 데이터. 처음 보는 사용자면 빈 데이터를 만든다.
  StubUserData of(String user) => _users.putIfAbsent(user, StubUserData.new);

  Map<String, dynamic> toJson() => {
        'users': {for (final e in _users.entries) e.key: e.value.toJson()},
        'activeTokens': activeTokens.toList(),
      };

  /// 사용자별로 나누기 전 형식(`users`가 없음)은 읽지 않고 버린다.
  void loadFrom(Map<String, dynamic> json) {
    _users.clear();
    activeTokens
      ..clear()
      ..addAll((json['activeTokens'] as List<dynamic>? ?? const []).cast<String>());
    final users = json['users'] as Map<String, dynamic>?;
    if (users == null) return;
    users.forEach((user, data) => _users[user] = StubUserData()..loadFrom(data as Map<String, dynamic>));
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

  void loadFrom(Map<String, dynamic> json) {
    profile = json['profile'] as Map<String, dynamic>?;
    transactions
      ..clear()
      ..addAll(_rows(json['transactions']));
    customCategories
      ..clear()
      ..addAll(_rows(json['customCategories']));
  }

  Map<String, Map<String, dynamic>> _rows(Object? raw) =>
      (raw as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as Map<String, dynamic>));
}
