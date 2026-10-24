import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/presentation/widget/common/income_picker.dart';
import 'package:sedae_budget/theme/theme.dart';

/// [income]에서 시작해 고른 값을 따라가는 소득 고르기.
Widget _picker(double income) => MaterialApp(
      theme: materialTheme(LightTheme()),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (_, setState) =>
              IncomePicker(income: income, onChanged: (v) => setState(() => income = v)),
        ),
      ),
    );

void main() {
  // 프로필 수정은 서버에 저장된 소득으로 열리므로 상한(600만)보다 클 수 있다.
  testWidgets('상한보다 큰 소득은 금액을 그대로 보이고 슬라이더는 끝에 선다', (t) async {
    await t.pumpWidget(_picker(7000000));

    expect(t.takeException(), isNull);
    expect(find.text('₩7,000,000'), findsOneWidget);
    expect(t.widget<Slider>(find.byType(Slider)).value, 6000000);
  });

  testWidgets('슬라이더는 10만 원 단위로 고른다', (t) async {
    await t.pumpWidget(_picker(0));

    final slider = t.getRect(find.byType(Slider));
    await t.tapAt(Offset(slider.left + slider.width * 31 / 60, slider.center.dy));
    await t.pump();
    expect(find.text('₩3,100,000'), findsOneWidget);
  });
}
