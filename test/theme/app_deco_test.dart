import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  test('radius scale matches design tokens', () {
    expect(CSize.sm.radius, 12);
    expect(CSize.card.radius, 20);
    expect(CSize.lg.radius, 22);
    expect(CSize.pill.radius, 999);
  });
  test('light theme exposes card and coral shadows', () {
    expect(LightTheme().deco.cardShadow, isNotEmpty);
    expect(LightTheme().deco.coralShadow, isNotEmpty);
  });
}
