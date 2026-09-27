import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/presentation/page/budget/widget/day_ad_banner.dart';

import '../../helper/fakes.dart';

/// 해제 횟수를 세는 320×100 fake 배너. 테스트마다 새로 만들어 횟수가 섞이지 않게 한다.
class _FakeBanner {
  int disposeCalls = 0;

  late final banner = LoadedBanner(
    width: 320,
    height: 100,
    view: const SizedBox(key: Key('ad-view')),
    dispose: () async {
      disposeCalls++;
    },
  );
}

/// [loaded]를 배너 로드 결과로 쓰는 [DayAdBanner]를 띄운다.
Future<void> _pump(WidgetTester tester, Future<LoadedBanner?> loaded) => tester.pumpWidget(fakeScope(
      fakeContainer(adService: FakeAdService(banner: loaded)),
      const MaterialApp(home: Scaffold(body: DayAdBanner())),
    ));

void main() {
  testWidgets('로드되면 광고 칩·캡션과 배너를 1px 테두리 프레임 안에 그린다', (tester) async {
    await _pump(tester, Future.value(_FakeBanner().banner));
    await tester.pump();

    expect(find.text('광고'), findsOneWidget);
    expect(find.text('AdMob · 320×100'), findsOneWidget);
    final view = find.byKey(const Key('ad-view'));
    expect(tester.getSize(view), const Size(320, 100));
    // 테두리가 광고를 가리지 않게 프레임은 배너보다 2px 높다.
    final frame = find.ancestor(of: view, matching: find.byType(Container)).first;
    expect(tester.getSize(frame).height, 102);
  });

  testWidgets('로드 중에 화면에서 빠지면 늦게 도착한 배너를 해제한다', (tester) async {
    final fake = _FakeBanner();
    final loading = Completer<LoadedBanner?>();
    await _pump(tester, loading.future);

    await tester.pumpWidget(const SizedBox());
    loading.complete(fake.banner);
    await tester.pump();

    expect(fake.disposeCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('로드된 배너는 화면에서 빠질 때 해제한다', (tester) async {
    final fake = _FakeBanner();
    await _pump(tester, Future.value(fake.banner));
    await tester.pump();
    expect(fake.disposeCalls, 0);

    await tester.pumpWidget(const SizedBox());

    expect(fake.disposeCalls, 1);
  });
}
