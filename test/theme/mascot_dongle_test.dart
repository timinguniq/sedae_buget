import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  testWidgets('renders at requested size', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MascotDongle(size: 48))));
    expect(find.byType(MascotDongle), findsOneWidget);
    expect(tester.getSize(find.byType(MascotDongle)), const Size(48, 48));
  });
}
