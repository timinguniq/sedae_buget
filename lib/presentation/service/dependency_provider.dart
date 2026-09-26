import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/app_config/remote_config.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';

/// 화면이 도메인 의존성을 얻는 seam.
///
/// 구현체는 composition root(`core/dependency_injection`, get_it)가 채우고,
/// 테스트는 이 provider를 `overrideWithValue`로 바꾼다. 그래서 화면 코드도 테스트도
/// 전역 locator를 직접 만지지 않는다 — locator를 아는 파일은 여기와 `ad_provider.dart`·`theme_mode_provider.dart`뿐이다.
final transactionUsecaseProvider =
    Provider<TransactionUsecase>((_) => locator<TransactionUsecase>());

final categoryUsecaseProvider =
    Provider<CategoryUsecase>((_) => locator<CategoryUsecase>());

final authUsecaseProvider = Provider<AuthUsecase>((_) => locator<AuthUsecase>());

final userProfileRepositoryProvider =
    Provider<UserProfileRepository>((_) => locator<UserProfileRepository>());

final peerStatsRepositoryProvider =
    Provider<PeerStatsRepository>((_) => locator<PeerStatsRepository>());

/// 점검·업데이트 판정 재료(원격 설정·빌드 번호).
final appStatusSourceProvider = Provider<AppStatusSource>((_) => locator<AppStatusSource>());
