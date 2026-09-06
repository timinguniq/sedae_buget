import 'package:sedae_budget/core/http_client/api_client.dart';
import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/data/remote/api_path.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 세션 인증. 액세스 토큰은 [AuthTokenStore]에 보관하고 요청 헤더는 인터셉터가 붙인다.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final AuthTokenStore _tokens;

  @override
  Future<AuthUser?> currentUser() async {
    if ((await _tokens.read()) == null) return null;
    try {
      return AuthUser.fromJson(await _api.get<Map<String, dynamic>>(ApiPath.me));
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> signIn(AuthProvider provider, String idToken) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiPath.login,
      body: {'provider': provider.name, 'idToken': idToken},
    );
    await _tokens.write(json['accessToken'] as String);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post<dynamic>(ApiPath.logout);
    } on ApiException {
      // best-effort: 서버가 응답하지 않아도 로컬 세션은 끝낸다.
    }
    await _tokens.clear();
  }
}
