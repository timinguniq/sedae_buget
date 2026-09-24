import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/main.dart';
import 'package:sedae_budget/presentation/page/main/main_shell.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

import '../../helper/fakes.dart';

const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  // 앱을 켤 때는 스플래시가 안내한다. 쓰는 중에 점검이 걸리면 MyApp이 지금 화면 위에 안내한다.
  testWidgets('쓰는 중 원격 설정이 점검으로 바뀌면 지금 화면 위에 안내한다', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final ads = FakeAdService();
    final source = FakeAppStatusSource();
    final container = fakeContainer(
      user: _user,
      profile: _profile,
      transactions: InMemoryTransactionRepository(),
      categories: InMemoryCategoryRepository(),
      peerRepository: FakePeerStatsRepository(),
      adService: ads,
      launchInterstitial: await fakeLaunchInterstitial(ads),
      appStatusSource: source,
    );
    await t.pumpWidget(fakeScope(
      container,
      provider.ChangeNotifierProvider(create: (_) => ThemeService(), child: const MyApp()),
    ));
    await t.pump(); // splash + postFrameCallback
    await t.pump(const Duration(milliseconds: 2100)); // splash 2초 경과
    await t.pump(); // 가드 → 홈
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(MainShell), findsOneWidget);

    source.updates.add(AppInitialInfo(
      android: const AppVersion(releaseVersion: 1, minimumAvailableVersion: 1, link: 'a'),
      ios: const AppVersion(releaseVersion: 1, minimumAvailableVersion: 1, link: 'i'),
      serviceStatus: AppServiceStatus(
        available: false,
        noticeTitle: '점검 중이에요',
        noticeContent: '곧 돌아올게요',
        expectedTimeToBeAvailable: DateTime(2026, 9, 24, 23),
      ),
    ));
    await t.pump(); // 갱신 판정
    await t.pump(const Duration(milliseconds: 300)); // 대화상자 등장

    expect(find.text('점검 중이에요'), findsOneWidget);
    expect(find.byType(MainShell), findsOneWidget); // 화면은 그대로, 위에 안내
  });
}
