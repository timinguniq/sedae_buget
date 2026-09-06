import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  testWidgets('renders at requested size', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MascotDongle(size: 48))));
    expect(find.byType(MascotDongle), findsOneWidget);
    expect(tester.getSize(find.byType(MascotDongle)), const Size(48, 48));
  });

  testWidgets('large size (ink features + cheeks) and custom colors render', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Row(children: [
      MascotDongle(size: 88),
      MascotDongle(size: 80, faceColor: Palette.cream, featureColor: Palette.primaryNormal),
    ]))));
    expect(find.byType(MascotDongle), findsNWidgets(2));
    expect(tester.getSize(find.byType(MascotDongle).first), const Size(88, 88));
  });
}
