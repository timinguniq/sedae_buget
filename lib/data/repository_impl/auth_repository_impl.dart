import 'package:sedae_budget/core/http_client/session.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';
import 'package:sedae_budget/data/data_source/remote/auth_api.dart';
import 'package:sedae_budget/data/dto/login_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

final _logger = CustomLogger.create(tag: 'auth');

/// 서버 세션 인증. 소셜 id_token은 [SocialIdTokenProvider]에서 받아 서버 세션으로 바꾸고,
/// 받은 토큰의 보관·요청 헤더·401·저장소 실패는 [Session]이 맡는다.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._session, this._social);

  final AuthApi _api;
  final Session _session;
  final SocialIdTokenProvider _social;

  @override
  Stream<void> get sessionExpired => _session.expired;

  @override
  Future<Result<AuthUser?>> currentUser() async {
    if (!await _session.isActive) return const Result.success(null);
    return guardApi<AuthUser?>(
      () async => (await _api.me()).toEntity(),
      // 무효한 세션은 없는 세션과 같다(세션은 이미 끝났고 만료로 알렸다).
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
    final started = (await _session.start(session.token)).failureOrNull;
    if (started != null) return Result.failure(started);
    return Result.success(session.user);
  }

  @override
  Future<Result<void>> signOut() => _session.end(tellServer: (authorization) async {
        // 서버가 응답하지 않아도 이 기기의 세션은 이미 끝났다.
        final server = (await guardApi(() => _api.logout(authorization))).failureOrNull;
        if (server != null) _logger.w('서버에 로그아웃을 알리지 못했어요(${server.reason.name}). 서버 세션은 만료로 끝나요');
      });
}
