import 'package:get_it/get_it.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';

final locator = GetIt.instance;

void configureDependencyInjection(LocalStorage storage) {
  _data(storage);
  _repository();
  _manager();
  _usecase();
}

void _data(LocalStorage storage) {
  /*
  locator
    ..registerSingleton<ArtistApi>(ArtistApi(CHttpClient.dio))
    ..registerSingleton<AuthApi>(AuthApi(CHttpClient.newDio))
    ..registerSingleton<CommonApi>(CommonApi(CHttpClient.dio))
    ..registerSingleton<CommunityApi>(CommunityApi(CHttpClient.dio))
    ..registerSingleton<ContentApi>(ContentApi(CHttpClient.dio))
    ..registerSingleton<DiscoverApi>(DiscoverApi(CHttpClient.dio))
    ..registerSingleton<EventApi>(EventApi(CHttpClient.dio))
    ..registerSingleton<KookyTvApi>(KookyTvApi(CHttpClient.dio))
  // LiveApi
    ..registerSingleton<MagazineApi>(MagazineApi(CHttpClient.dio))
    ..registerSingleton<MainApi>(MainApi(CHttpClient.dio))
    ..registerSingleton<MyKookyApi>(MyKookyApi(CHttpClient.dio))
    ..registerSingleton<MyLoovyApi>(MyLoovyApi(CHttpClient.dio))
    ..registerSingleton<NotificationOldApi>(NotificationOldApi(CHttpClient.dio))
    ..registerSingleton<NotificationApi>(NotificationApi(CHttpClient.dio))
    ..registerSingleton<PostApi>(PostApi(CHttpClient.dio))
    ..registerSingleton<PurchaseApi>(PurchaseApi(CHttpClient.newDio))
  // SettingApi
    ..registerSingleton<TrendApi>(TrendApi(CHttpClient.dio))
    ..registerSingleton<UserApi>(UserApi(CHttpClient.dio))
    ..registerSingleton<UserPageApi>(UserPageApi(CHttpClient.dio))
    ..registerSingleton<VoteApi>(VoteApi(CHttpClient.dio))

  // storage
    ..registerSingleton<AppSettingStorage>(AppSettingStorage(storage))
    ..registerSingleton<AuthStorage>(AuthStorage(storage))
    ..registerSingleton<NotificationStorage>(NotificationStorage(storage));

   */
}

void _repository() {
  /*
  locator
    ..registerSingleton<AppSettingRepository>(AppSettingRepositoryImpl(locator<AppSettingStorage>()))
    ..registerSingleton<AuthRepository>(
      AuthRepositoryImpl(locator<AuthApi>(), locator<AuthStorage>()),
    )
  // BuddyRepository)
    ..registerSingleton<CommentRepository>(CommentRepositoryImpl(locator<CommonApi>()))
    ..registerSingleton<CommonRepository>(CommonRepositoryImpl(locator<CommonApi>()))
    ..registerSingleton<CommunityRepository>(
      CommunityRepositoryImpl(locator<CommunityApi>(), locator<ArtistApi>(), locator<UserApi>()),
    )
    ..registerSingleton<ContentRepository>(
      ContentRepositoryImpl(locator<ContentApi>(), locator<MagazineApi>(), locator<KookyTvApi>()),
    )
    ..registerSingleton<DiscoverRepository>(DiscoverRepositoryImpl(locator<DiscoverApi>()))
    ..registerSingleton<EventRepository>(EventRepositoryImpl(locator<EventApi>()))
  // LiveRepository
    ..registerSingleton<MainRepository>(MainRepositoryImpl(locator<MainApi>()))
    ..registerSingleton<NotificationRepository>(
      NotificationRepositoryImpl(
        locator<NotificationOldApi>(),
        locator<NotificationApi>(),
        locator<NotificationStorage>(),
      ),
    )
    ..registerSingleton<PointRepository>(
      PointRepositoryImpl(locator<MyKookyApi>(), locator<MyLoovyApi>(), locator<UserPageApi>()),
    )
    ..registerSingleton<PostRepository>(PostRepositoryImpl(locator<PostApi>()))
    ..registerSingleton<PurchaseRepository>(PurchaseRepositoryImpl(locator<PurchaseApi>()))
  // SettingRepository
    ..registerSingleton<TrendRepository>(TrendRepositoryImpl(locator<TrendApi>()))
    ..registerSingleton<UserRepository>(
      UserRepositoryImpl(locator<UserApi>(), locator<CommonApi>(), locator<UserPageApi>()),
    )
    ..registerSingleton<UserPageRepository>(UserPageRepositoryImpl(locator<UserPageApi>()))
    ..registerSingleton<VoteRepository>(VoteRepositoryImpl(locator<VoteApi>()));

   */
}

void _usecase() {
  /*
  locator
    ..registerSingleton<AuthUsecase>(AuthUsecase(locator<AuthRepository>()))
    ..registerSingleton<CommentUsecase>(CommentUsecase(locator<CommentRepository>()))
    ..registerSingleton<CommunityUsecase>(CommunityUsecase(locator<CommunityRepository>()))
    ..registerSingleton<ContentUsecase>(ContentUsecase(locator<ContentRepository>()))
    ..registerSingleton<DiscoverUsecase>(DiscoverUsecase(locator<DiscoverRepository>()))
    ..registerSingleton<EventUsecase>(EventUsecase(locator<EventRepository>()))
    ..registerSingleton<HomeUsecase>(HomeUsecase(locator<MainRepository>()))
    ..registerSingleton(NotificationUsecase(locator<NotificationRepository>()))
    ..registerSingleton<PointUsecase>(PointUsecase(locator<PointRepository>()))
    ..registerSingleton<PostUsecase>(PostUsecase(locator<PostRepository>()))
    ..registerSingleton<PurchaseUsecase>(PurchaseUsecase(locator<PurchaseRepository>()))
    ..registerSingleton<UserUsecase>(UserUsecase(locator<UserRepository>(), locator<UserPageRepository>()))
    ..registerSingleton<VoteUsecase>(VoteUsecase(locator<TrendRepository>(), locator<VoteRepository>()));

   */
}

void _manager() {
  /*
  locator
    ..registerSingleton<AppSettingManager>(AppSettingManager(locator<AppSettingRepository>()))
    ..registerSingleton<AuthTokenManager>(AuthTokenManager(locator<AuthRepository>()))
    ..registerSingleton<NotificationManager>(NotificationManager(locator<NotificationRepository>()));

   */
}

/// Phase 1 로컬 가계부 의존성. Firebase 없이 독립 실행 가능.
void configureBudgetDependencies() {
  if (locator.isRegistered<TransactionUsecase>()) return;
  final db = AppDatabase();
  locator
    ..registerSingleton<AppDatabase>(db)
    ..registerSingleton<TransactionLocalDataSource>(
      DriftTransactionLocalDataSource(db.transactionDao),
    )
    ..registerSingleton<TransactionRepository>(
      TransactionRepositoryImpl(locator<TransactionLocalDataSource>()),
    )
    ..registerSingleton<TransactionUsecase>(
      TransactionUsecase(locator<TransactionRepository>()),
    );
}

/// 또래 통계 의존성. 현재 목업, 서버 구현 시 이 함수만 교체.
void configurePeerDependencies() {
  if (locator.isRegistered<PeerStatsRepository>()) return;
  locator.registerSingleton<PeerStatsRepository>(MockPeerStatsRepository());
}

/// 인증·프로필 의존성. 현재 SharedPreferences 로컬, 서버 도입 시 구현체만 교체.
void configureUserDependencies() {
  if (locator.isRegistered<AuthUsecase>()) return;
  locator
    ..registerSingleton<AuthRepository>(SharedPrefsAuthRepository())
    ..registerSingleton<AuthUsecase>(AuthUsecase(locator<AuthRepository>()))
    ..registerSingleton<UserProfileRepository>(
      SharedPrefsUserProfileRepository(),
    );
}
