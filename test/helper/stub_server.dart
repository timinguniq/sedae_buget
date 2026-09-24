import 'package:dio/dio.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import 'test_api_client.dart';

/// 테스트용 인메모리 토큰 저장소.
class MemoryAuthTokenStore implements AuthTokenStore {
  MemoryAuthTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

/// 운영과 같은 배선(`ApiClient.create` = 토큰 인터셉터 → 로거 → Stub)으로 만든 가짜 서버.
///
/// 저장소 구현은 모두 같은 [dio]·[tokens]를 쓴다. 그래서 로그인하면 다른 저장소도 그 사용자로 부르고,
/// 서버가 토큰을 거부하면(401) [sessionExpiry]가 알린다.
class StubServer {
  factory StubServer({StubStateStore? store}) =>
      StubServer._(MemoryAuthTokenStore(), SessionExpiry(), store);

  StubServer._(this.tokens, this.sessionExpiry, StubStateStore? store)
      : dio = ApiClient.create(
          baseUrl: '',
          tokenStore: tokens,
          sessionExpiry: sessionExpiry,
          extra: [StubApiInterceptor(store: store)],
        ).dio;

  final Dio dio;
  final MemoryAuthTokenStore tokens;
  final SessionExpiry sessionExpiry;

  /// 경로·바디 단위로 계약을 검증할 때 쓴다.
  TestApiClient get api => TestApiClient(dio);

  AuthRepository get auth => AuthRepositoryImpl(AuthApi(dio), tokens, sessionExpiry);
  UserProfileRepository get profiles => UserProfileRepositoryImpl(UserProfileApi(dio));
  TransactionRepository get transactions => TransactionRepositoryImpl(TransactionApi(dio));
  CategoryRepository get categories => CategoryRepositoryImpl(CategoryApi(dio));
  PeerStatsRepository get peerStats => PeerStatsRepositoryImpl(PeerStatsApi(dio));

  /// 실제 로그인 요청으로 [provider] 사용자가 된다.
  Future<void> signIn(AuthProvider provider) async =>
      (await auth.signIn(provider, 'test-id-token')).unwrap();
}
