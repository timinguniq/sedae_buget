import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/local_storage/secure_auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 보안 저장소 비우기가 실패하는 기기(키 저장소 고장).
class _WipeFails extends FlutterSecureStorage {
  const _WipeFails();

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      throw PlatformException(code: 'keystore');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // iOS 키체인은 앱을 지워도 남는다: 지운 앱의 토큰이 저장소에 있는 상태로 시작한다.
  setUp(() => FlutterSecureStorage.setMockInitialValues({'access_token': 'left-over'}));

  test('설치 뒤 처음 켜면 남은 토큰을 지우고, 다음 실행부터는 지우지 않는다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = await SecureAuthTokenStore.open(prefs);
    expect(await first.read(), isNull);
    await first.write('mine');

    final next = await SecureAuthTokenStore.open(prefs);
    expect(await next.read(), 'mine');
  });

  // 이전에는 여기서 던져 앱이 뜨지 않았다.
  test('비우지 못해도 열리고, 그 실행은 남은 토큰을 쓰지 않으며, 다음 실행에 다시 비운다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final broken = await SecureAuthTokenStore.open(prefs, storage: const _WipeFails());
    expect(await broken.read(), isNull);
    await broken.write('mine'); // 이번 실행에 새로 로그인하면 그 토큰은 쓴다
    expect(await broken.read(), 'mine');

    FlutterSecureStorage.setMockInitialValues({'access_token': 'left-over'});
    final next = await SecureAuthTokenStore.open(prefs);
    expect(await next.read(), isNull);
  });
}
