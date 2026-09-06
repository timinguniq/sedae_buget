import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 소셜 SDK 미도입 상태의 자리표시 토큰. Stub 서버는 값을 검사하지 않는다.
class StubSocialIdTokenProvider implements SocialIdTokenProvider {
  @override
  Future<String> idToken(AuthProvider provider) async => 'stub-id-token:${provider.name}';
}
