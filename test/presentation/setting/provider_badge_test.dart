import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/setting/widget/provider_badge.dart';

void main() {
  testWidgets('ProviderBadge shows each provider label', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Row(children: [
      ProviderBadge(provider: AuthProvider.kakao),
      ProviderBadge(provider: AuthProvider.naver),
      ProviderBadge(provider: AuthProvider.google),
    ]))));
    for (final p in AuthProvider.values) {
      expect(find.text(p.label), findsOneWidget);
    }
  });
}
