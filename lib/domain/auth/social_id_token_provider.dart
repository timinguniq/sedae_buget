import 'package:sedae_budget/entity/entity.dart';

/// 소셜 SDK에서 OIDC id_token을 받아오는 자리. 현재는 Stub, SDK 도입 시 구현체 추가.
abstract class SocialIdTokenProvider {
  Future<String> idToken(AuthProvider provider);
}
