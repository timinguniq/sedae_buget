import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';

/// 서버에 닿는 저장소 다섯과 그 세션. 앱(DI)과 테스트(`StubServer`)가 이 조립 하나를 쓴다.
///
/// 저장소는 모두 같은 [dio]·[session]을 쓴다. 그래서 로그인하면 다른 저장소도 그 사용자로 부르고,
/// 서버가 토큰을 거부하면(401) [session]이 만료를 알린다.
class ServerRepositories {
  /// [env]의 서버에 연결한다([connectToServer]). local이면 [localServer]가 서버 대신 답하고,
  /// [beforeServer]는 그 바로 앞에 선다. 요청 로그는 [requestLog]일 때만 남긴다(앱: release가 아닐 때).
  factory ServerRepositories.connect({
    required AppEnvironment env,
    required AuthTokenStore tokenStore,
    required Interceptor Function() localServer,
    List<Interceptor> beforeServer = const [],
    bool requestLog = !kReleaseMode,
  }) {
    final session = Session(tokenStore);
    return ServerRepositories._(
      session,
      connectToServer(
        env: env,
        session: session,
        localServer: localServer,
        beforeServer: beforeServer,
        requestLog: requestLog,
      ),
    );
  }

  ServerRepositories._(this.session, this.dio)
      : auth = AuthRepositoryImpl(AuthApi(dio), session, StubSocialIdTokenProvider()),
        profiles = UserProfileRepositoryImpl(UserProfileApi(dio)),
        transactions = TransactionRepositoryImpl(TransactionApi(dio)),
        categories = CategoryRepositoryImpl(CategoryApi(dio)),
        peerStats = PeerStatsRepositoryImpl(PeerStatsApi(dio));

  final Session session;
  final Dio dio;
  final AuthRepository auth;
  final UserProfileRepository profiles;
  final TransactionRepository transactions;
  final CategoryRepository categories;
  final PeerStatsRepository peerStats;
}
