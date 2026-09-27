import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = CustomLogger.create(tag: 'token-store');

/// 액세스 토큰을 보안 저장소(iOS 키체인·Android 암호화 저장소)에 두는 [AuthTokenStore] adapter.
///
/// iOS 키체인은 앱을 지워도 남는다(https://stackoverflow.com/a/57937650/576440). 그래서 설치 뒤 처음 켤 때
/// 보안 저장소를 비운다. 비우지 못해도 앱은 켜지고, 그 실행에서는 남은 토큰을 믿지 않으며(없는 것으로 읽는다)
/// 다음 실행에 다시 비운다. 지운 앱의 계정으로 저절로 로그인되지 않게 하기 위해서다.
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore._(this._storage, this._trustSaved);

  /// 설치 뒤 처음이면 보안 저장소를 비우고 연다. [storage]는 테스트가 바꾼다.
  static Future<SecureAuthTokenStore> open(
    SharedPreferences prefs, {
    FlutterSecureStorage storage = _secure,
  }) async {
    if (!(prefs.getBool(_firstRunKey) ?? true)) return SecureAuthTokenStore._(storage, true);
    try {
      await storage.deleteAll();
      await prefs.setBool(_firstRunKey, false);
      return SecureAuthTokenStore._(storage, true);
    } catch (e, s) {
      _logger.e('설치 뒤 보안 저장소를 비우지 못했어요. 이번 실행은 남은 토큰을 쓰지 않아요', error: e, stackTrace: s);
      return SecureAuthTokenStore._(storage, false);
    }
  }

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _firstRunKey = 'first_run';
  static const _key = 'access_token';

  final FlutterSecureStorage _storage;

  /// 남은 토큰을 믿는가. 설치 뒤 비우지 못했으면 이번 실행에서 새로 쓰기 전까지 false.
  bool _trustSaved;

  @override
  Future<String?> read() async => _trustSaved ? _storage.read(key: _key) : null;

  @override
  Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    _trustSaved = true;
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
