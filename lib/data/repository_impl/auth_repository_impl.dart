import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/data/data_source/remote/auth_api.dart';
import 'package:sedae_budget/data/dto/login_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 세션 인증. 액세스 토큰은 [AuthTokenStore]에 보관하고 요청 헤더는 인터셉터가 붙인다.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens);

  final AuthApi _api;
  final AuthTokenStore _tokens;

  @override
  Future<AuthUser?> currentUser() async {
    if ((await _tokens.read()) == null) return null;
    try {
      return (await callApi(_api.me)).toEntity();
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
    final res = await callApi(
      () => _api.login(LoginRequestDto(provider: provider, idToken: idToken)),
    );
    await _tokens.write(res.accessToken);
    return res.user.toEntity();
  }

  @override
  Future<void> signOut() async {
    try {
      await callApi(_api.logout);
    } on ApiException {
      // best-effort: 서버가 응답하지 않아도 로컬 세션은 끝낸다.
    }
    await _tokens.clear();
  }
}
