import 'package:sedae_budget/core/local_storage/local_storage.dart';

/// 액세스 토큰 보관. 구현: secure storage(앱), 인메모리(테스트).
abstract class AuthTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore(this._storage);

  static const _key = 'access_token';

  final LocalStorage _storage;

  @override
  Future<String?> read() => _storage.read(_key);

  @override
  Future<void> write(String token) => _storage.write(_key, token);

  @override
  Future<void> clear() => _storage.delete(_key);
}
