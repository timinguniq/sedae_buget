import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import 'server_faults.dart';

export 'server_faults.dart';

/// Stub이 kakao 로그인에 돌려주는 사용자.
const testUser = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');

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

/// 운영의 local 환경과 같은 배선(`connectToServer` = 토큰 인터셉터 → 로거 → Stub)으로 만든 가짜 서버.
/// 테스트가 쓰는 유일한 서버 adapter다.
///
/// 저장소 구현은 모두 같은 [dio]·[tokens]를 쓴다. 그래서 로그인하면 다른 저장소도 그 사용자로 부르고,
/// 서버가 토큰을 거부하면(401) [sessionExpiry]가 알린다. Stub 바로 앞의 [faults]로 장애·느린 응답을
/// 흉내 내고 서버에 닿은 요청을 센다. [peerStats]를 주면 Stub이 그 또래 통계로 답한다.
class StubServer {
  factory StubServer({StubStateStore? store, PeerStats Function(AgeGroup)? peerStats}) =>
      StubServer._(MemoryAuthTokenStore(), SessionExpiry(), ServerFaults(), store, peerStats);

  StubServer._(this.tokens, this.sessionExpiry, this.faults, StubStateStore? store,
      PeerStats Function(AgeGroup)? peerStats)
      : dio = connectToServer(
          env: AppEnvironment.local,
          tokenStore: tokens,
          sessionExpiry: sessionExpiry,
          localServer: () => StubApiInterceptor(store: store, peerStats: peerStats),
        ) {
    dio.interceptors.insert(dio.interceptors.length - 1, faults);
  }

  final Dio dio;
  final MemoryAuthTokenStore tokens;
  final SessionExpiry sessionExpiry;
  final ServerFaults faults;

  AuthRepository get auth => AuthRepositoryImpl(AuthApi(dio), tokens, sessionExpiry);
  UserProfileRepository get profiles => UserProfileRepositoryImpl(UserProfileApi(dio));
  TransactionRepository get transactions => TransactionRepositoryImpl(TransactionApi(dio));
  CategoryRepository get categories => CategoryRepositoryImpl(CategoryApi(dio));
  PeerStatsRepository get peerStats => PeerStatsRepositoryImpl(PeerStatsApi(dio));

  /// 실제 로그인 요청으로 [provider] 사용자가 된다.
  Future<void> signIn(AuthProvider provider) async =>
      (await auth.signIn(provider, 'test-id-token')).unwrap();

  /// [provider]로 로그인하고 [profile]·[categories]·[transactions]를 실제 API로 심는다.
  Future<void> seed({
    AuthProvider provider = AuthProvider.kakao,
    UserProfile? profile,
    List<CustomCategory> categories = const [],
    List<Transaction> transactions = const [],
  }) async {
    await signIn(provider);
    if (profile != null) (await profiles.save(profile)).unwrap();
    for (final c in categories) {
      (await this.categories.upsert(c)).unwrap();
    }
    for (final t in transactions) {
      (await this.transactions.upsert(t)).unwrap();
    }
  }

  /// 쓰는 중에 서버가 세션을 끝낸 상황: 저장된 토큰이 거부되어(401) 토큰이 지워지고 만료가 알려진다.
  Future<void> expireSession() async {
    tokens.token = 'expired';
    await auth.currentUser();
  }
}

/// 위젯 테스트(FakeAsync)에서 서버를 다룬다.
///
/// Dio 요청은 (가짜) 시간이 흘러야 끝나므로 [untilDone]으로 시간을 흘린다. `runAsync`(진짜 시간)로
/// 준비하면 그때 만든 Future가 진짜 시간에 묶여, 이후 위젯이 보내는 요청이 끝나지 않는다.
extension StubServerInWidgetTest on WidgetTester {
  /// [work]가 끝날 때까지 가짜 시간을 흘리고 그 결과를 돌려준다.
  Future<T> untilDone<T>(Future<T> work) async {
    var done = false;
    work.whenComplete(() => done = true).ignore();
    for (var i = 0; !done; i++) {
      if (i > 1000) throw StateError('서버 요청이 끝나지 않았어요');
      await pump(Duration.zero);
    }
    return work;
  }

  /// 화면이 서버 응답을 다 받아 그릴 때까지 흘린다. [pumpAndSettle]은 그릴 프레임이 없으면 멈추는데,
  /// 막 그린 위젯이 보낸 요청(Dio의 0초 타이머)은 프레임이 아니라서 시간을 한 번 더 흘려야 끝난다.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await pump(Duration.zero);
      await pumpAndSettle();
    }
  }

  /// 서버를 만들고 [provider]로 로그인해 [profile]·[categories]·[transactions]를 심는다.
  /// [provider]가 null이면 로그인하지 않은 빈 서버다.
  Future<StubServer> seedServer({
    AuthProvider? provider = AuthProvider.kakao,
    UserProfile? profile,
    List<CustomCategory> categories = const [],
    List<Transaction> transactions = const [],
    PeerStats Function(AgeGroup)? peerStats,
  }) async {
    final server = StubServer(peerStats: peerStats);
    if (provider != null) {
      await untilDone(server.seed(
        provider: provider,
        profile: profile,
        categories: categories,
        transactions: transactions,
      ));
    }
    return server;
  }
}
