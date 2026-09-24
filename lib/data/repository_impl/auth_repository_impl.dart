import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/http_client/session_expiry.dart';
import 'package:sedae_budget/data/data_source/remote/auth_api.dart';
import 'package:sedae_budget/data/dto/login_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 세션 인증. 액세스 토큰은 [AuthTokenStore]에 보관하고 요청 헤더는 인터셉터가 붙인다.
/// 서버가 토큰을 거부하면(401) 인터셉터가 토큰을 지우고 [SessionExpiry]로 알린다.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens, this._expiry);

  final AuthApi _api;
  final AuthTokenStore _tokens;
  final SessionExpiry _expiry;

  @override
  Stream<void> get sessionExpired => _expiry.expired;

  @override
  Future<Result<AuthUser?>> currentUser() async {
    if ((await _tokens.read()) == null) return const Result.success(null);
    try {
      return Result.success((await callApi(_api.me)).toEntity());
    } on ApiException catch (e) {
      // 무효한 세션은 없는 세션과 같다(토큰은 인터셉터가 이미 버렸다).
      if (e.isUnauthorized) return const Result.success(null);
      return Result.failure(toErrorResult(e));
    }
  }

  @override
  Future<Result<AuthUser>> signIn(AuthProvider provider, String idToken) async {
    try {
      final res = await callApi(
        () => _api.login(LoginRequestDto(provider: provider, idToken: idToken)),
      );
      await _tokens.write(res.accessToken);
      return Result.success(res.user.toEntity());
    } on ApiException catch (e) {
      return Result.failure(toErrorResult(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    ErrorResult? failure;
    try {
      await callApi(_api.logout);
    } on ApiException catch (e) {
      // 서버가 응답하지 않아도 로컬 세션은 끝낸다. 다만 실패는 삼키지 않는다.
      failure = toErrorResult(e);
    }
    await _tokens.clear();
    return failure == null ? const Result.success(null) : Result.failure(failure);
  }
}
