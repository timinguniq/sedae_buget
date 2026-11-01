import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sedae_budget/presentation/page/budget/category_analysis.page.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_edit.page.dart';
import 'package:sedae_budget/presentation/page/legal/legal.page.dart';
import 'package:sedae_budget/presentation/page/legal/legal_content.dart';
import 'package:sedae_budget/presentation/page/setting/profile_edit.page.dart';
import 'package:sedae_budget/presentation/presentation.dart';

import '../../helper/fakes.dart';

/// push로 여는 화면과 그 닫기 버튼의 아이콘.
final _pages = <String, (Widget, IconData)>{
  '설정': (const SettingPage(), Icons.chevron_left),
  '프로필 수정': (const ProfileEditPage(), Icons.chevron_left),
  '카테고리 분석': (const CategoryAnalysisPage(), Icons.chevron_left),
  '거래 입력': (const TransactionEditPage(), Icons.close),
  '약관': (const LegalPage(initialTab: LegalTab.terms), Icons.chevron_left),
};

void main() {
  setUpAll(() => initializeDateFormatting('ko')); // 거래 입력의 날짜 표기
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'sedae',
      packageName: 'com.sedae.budget',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  // 이전에는 웹에서 주소로 바로 연 화면(돌아갈 화면 없음)의 닫기가 go_router의 "nothing to pop" 오류였다.
  // 약관만 홈으로 보냈다. 실제 행선지는 전역 가드가 정한다.
  for (final MapEntry(key: name, value: (page, icon)) in _pages.entries) {
    testWidgets('$name: 돌아갈 화면이 없으면 닫기는 홈으로 간다', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      final server = await t.seedServer(profile: noIncomeProfile);
      final container = fakeContainer(
        server: server,
        themeModeStore: await fakeThemeModeStore(),
      );
      final router = GoRouter(
        initialLocation: '/page',
        routes: [
          GoRoute(path: '/page', builder: (_, _) => page),
          GoRoute(
            path: RoutePath.budgetHome.path,
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
        ],
      );
      await t.pumpWidget(
        fakeScope(container, MaterialApp.router(routerConfig: router)),
      );
      await t.settle();

      await t.tap(find.byIcon(icon));
      await t.settle();

      expect(t.takeException(), isNull);
      expect(find.text('HOME'), findsOneWidget);
    });
  }
}
