import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/age_group_picker.dart';
import 'package:sedae_budget/theme/theme.dart';

/// [group] 카드의 배경색.
Color? _cardColor(WidgetTester t, AgeGroup group) {
  final card = t.widget<Container>(
      find.ancestor(of: find.text(group.label), matching: find.byType(Container)).first);
  return (card.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('고른 나이대 카드만 선택 색(코랄 틴트)으로 보인다', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: materialTheme(LightTheme()),
      home: Scaffold(body: AgeGroupPicker(selected: AgeGroup.thirties, onSelect: (_) {})),
    ));

    for (final g in AgeGroup.values) {
      expect(_cardColor(t, g), g == AgeGroup.thirties ? Palette.coralTint : Palette.surface,
          reason: g.label);
    }
  });
}
