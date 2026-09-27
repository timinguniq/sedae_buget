import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/http_client/session_expiry.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';
import 'package:sedae_budget/data/data_source/remote/auth_api.dart';
import 'package:sedae_budget/data/dto/login_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

final _logger = CustomLogger.create(tag: 'auth');

/// 토큰 저장소(secure storage) 호출([run])을 [Result]로 바꾼다. 실패는 던지지 않고 unknown으로 돌려준다.
Future<Result<T>> _guardTokens<T>(Future<T> Function() run) async {
  try {
    return Result.success(await run());
  } catch (e, s) {
    _logger.e('토큰 저장소에 접근하지 못했어요', error: e, stackTrace: s);
    return const Result.failure(ErrorResult(reason: FailureReason.unknown, message: ''));
  }
}

/// 서버 세션 인증. 소셜 id_token은 [SocialIdTokenProvider]에서 받아 서버 세션으로 바꾼다.
/// 액세스 토큰은 [AuthTokenStore]에 보관하고 요청 헤더는 인터셉터가 붙인다.
/// 서버가 토큰을 거부하면(401) 인터셉터가 토큰을 지우고 [SessionExpiry]로 알린다.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens, this._expiry, this._social);

  final AuthApi _api;
  final AuthTokenStore _tokens;
  final SessionExpiry _expiry;
  final SocialIdTokenProvider _social;

  @override
  Stream<void> get sessionExpired => _expiry.expired;

  @override
  Future<Result<AuthUser?>> currentUser() async {
    final token = await _guardTokens(_tokens.read);
    final failure = token.failureOrNull;
    if (failure != null) return Result.failure(failure);
    if (token.unwrap() == null) return const Result.success(null);
    return guardApi<AuthUser?>(
      () async => (await _api.me()).toEntity(),
      // 무효한 세션은 없는 세션과 같다(토큰은 인터셉터가 이미 버렸다).
      recover: (f) => f.reason == FailureReason.unauthorized ? const Result.success(null) : null,
    );
  }

  @override
  Future<Result<AuthUser>> signIn(AuthProvider provider) async {
    final idToken = await _social.idToken(provider);
    final socialFailure = idToken.failureOrNull;
    if (socialFailure != null) return Result.failure(socialFailure);
    final res = await guardApi(() async {
      final login = await _api.login(LoginRequestDto(provider: provider, idToken: idToken.unwrap()));
      return (token: login.accessToken, user: login.user.toEntity());
    });
    final failure = res.failureOrNull;
    if (failure != null) return Result.failure(failure);
    final session = res.unwrap();
    final storeFailure = (await _guardTokens(() => _tokens.write(session.token))).failureOrNull;
    if (storeFailure != null) return Result.failure(storeFailure);
    return Result.success(session.user);
  }

  @override
  Future<Result<void>> signOut() async {
    // 서버가 응답하지 않아도 로컬 세션은 끝낸다. 다만 실패는 삼키지 않는다(서버 실패를 먼저 알린다).
    final res = await guardApi(_api.logout);
    final cleared = await _guardTokens(_tokens.clear);
    return res.failureOrNull != null ? res : cleared;
  }
}
