import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/widget/social_login_button.dart';

void main() {
  testWidgets('each provider renders label + svg logo and fires onTap', (t) async {
    AuthProvider? tapped;
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Column(children: [
      for (final p in AuthProvider.values)
        SocialLoginButton(provider: p, onTap: () => tapped = p),
    ]))));
    await t.pump();

    expect(find.byType(SvgPicture), findsNWidgets(3));
    expect(find.text('네이버로 시작하기'), findsOneWidget);
    expect(t.getSize(find.byType(SocialLoginButton).first).height, SocialLoginButton.height + 11);

    await t.tap(find.text('Google로 시작하기'));
    expect(tapped, AuthProvider.google);
  });
}
