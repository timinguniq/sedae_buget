import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/app_status_dialog.dart';
import 'package:sedae_budget/theme/theme.dart';

const _version = AppVersion(releaseVersion: 20, minimumAvailableVersion: 15, link: 'store-link');

final _maintenance = AppUnderMaintenance(AppServiceStatus(
  available: false,
  noticeTitle: '점검 중이에요',
  noticeContent: '곧 돌아올게요',
  expectedTimeToBeAvailable: DateTime(2026, 9, 24, 23),
));

/// 앱처럼 GoRouter 위의 두 번째 화면에서 안내를 띄운다(닫을 때 아래 화면까지 닫히지 않는지 보려고).
class _Harness {
  bool? result;
  final log = <String>[];

  Future<void> open(WidgetTester t, AppStatus status) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => TextButton(
            onPressed: () => context.push('/second'), child: const Text('HOME')),
      ),
      GoRoute(
        path: '/second',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showAppStatusDialog(
              context,
              status,
              exitApp: () => log.add('exit'),
              openStore: (url) async => log.add('store $url'),
            ),
            child: const Text('SECOND'),
          ),
        ),
      ),
    ]);
    await t.pumpWidget(MaterialApp.router(routerConfig: router, theme: materialTheme(LightTheme())));
    await t.tap(find.text('HOME'));
    await t.pumpAndSettle();
    await t.tap(find.text('SECOND'));
    await t.pumpAndSettle();
  }
}

void main() {
  testWidgets('쓸 수 있으면 아무것도 띄우지 않고 계속한다', (t) async {
    final h = _Harness();
    await h.open(t, const AppAvailable());
    expect(find.byType(Dialog), findsNothing);
    expect(h.result, isTrue);
  });

  testWidgets('점검 중이면 원격 안내를 보여주고, 확인하면 앱을 끝낸다', (t) async {
    final h = _Harness();
    await h.open(t, _maintenance);
    expect(find.text('점검 중이에요'), findsOneWidget);
    expect(find.text('곧 돌아올게요'), findsOneWidget);

    await t.tap(find.text('확인'));
    await t.pumpAndSettle();

    expect(h.log, ['exit']);
    expect(h.result, isFalse);
  });

  // 이전에는 닫기 버튼이 대화상자를 닫은 뒤 한 번 더 pop해서 아래 화면까지 닫았다.
  testWidgets('선택 업데이트는 닫으면 대화상자만 닫히고 계속 쓴다', (t) async {
    final h = _Harness();
    await h.open(t, const AppUpdateAvailable(_version, forced: false));

    await t.tap(find.text('닫기'));
    await t.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('SECOND'), findsOneWidget);
    expect(h.log, isEmpty);
    expect(h.result, isTrue);
  });

  testWidgets('강제 업데이트는 닫을 수 없고, 업데이트하면 스토어를 열고 앱을 끝낸다', (t) async {
    final h = _Harness();
    await h.open(t, const AppUpdateAvailable(_version, forced: true));
    expect(find.text('닫기'), findsNothing);

    await t.tap(find.text('업데이트'));
    await t.pumpAndSettle();

    expect(h.log, ['store store-link', 'exit']);
    expect(h.result, isFalse);
  });
}
