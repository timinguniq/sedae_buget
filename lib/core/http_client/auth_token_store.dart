/// 액세스 토큰 보관. adapter: 보안 저장소(앱, `core/local_storage/secure_auth_token_store.dart`), 메모리(테스트).
/// 기기 저장소라 어떤 작업이든 던질 수 있다. 던진 것을 어떻게 볼지는 `Session`(`session.dart`)이 정한다.
abstract class AuthTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}
