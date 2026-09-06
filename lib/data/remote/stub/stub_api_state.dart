import 'package:shared_preferences/shared_preferences.dart';

/// Stub 서버의 "DB". 프로필 1개 + 거래 id→JSON + 사용자 카테고리 id→JSON(생성 순서 유지).
class StubApiState {
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

/// Stub 상태 영속화. 앱 재시작 후에도 온보딩·거래가 유지되게 한다.
abstract class StubStateStore {
  Future<String?> load();
  Future<void> save(String json);
}

class SharedPrefsStubStateStore implements StubStateStore {
  static const _key = 'stub_api_state';

  @override
  Future<String?> load() async => (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> save(String json) async =>
      (await SharedPreferences.getInstance()).setString(_key, json);
}
