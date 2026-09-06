import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

Widget _wrap(Widget child) => provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(
          home: Scaffold(body: child), theme: ThemeService().lightThemeData()));

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  final tx = Transaction.create(
    amount: 400000,
    categoryId: 1,
    date: DateTime(2026, 6, 10),
    type: TransactionType.expense,
  );

  testWidgets('overPeer=true renders 또래보다 잦음 badge', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(SizedBox(width: 390, child: TransactionTile(tx: tx, overPeer: true))));
    await tester.pump();

    expect(find.text('또래보다 잦음'), findsOneWidget);
  });

  testWidgets('overPeer defaults false — no badge rendered', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(SizedBox(width: 390, child: TransactionTile(tx: tx))));
    await tester.pump();

    expect(find.text('또래보다 잦음'), findsNothing);
  });

  // 회귀: 긴 메모 + 배지가 좁은 폭에서 RenderFlex 오버플로 없이 렌더되어야 한다
  // (date/memo Text가 Flexible + ellipsis 처리되는지 검증).
  testWidgets('overPeer=true with long memo does not overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final longTx = Transaction.create(
      amount: 400000,
      categoryId: 1,
      date: DateTime(2026, 6, 10),
      type: TransactionType.expense,
      memo: '오늘 마트에서 장 봤어요 그리고 또 다른 것도 많이 샀습니다 정말로',
    );

    await tester.pumpWidget(_wrap(SizedBox(width: 390, child: TransactionTile(tx: longTx, overPeer: true))));
    await tester.pump();

    expect(find.text('또래보다 잦음'), findsOneWidget);
  });
}
