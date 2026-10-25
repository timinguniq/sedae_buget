import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/presentation/page/legal/legal.page.dart';
import 'package:sedae_budget/presentation/page/legal/legal_content.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

const _termsTitle = '세대 가계부 이용약관';
const _privacyTitle = '개인정보처리방침';
const _summaryLabel = '한눈에 보기';
const _meta = '시행 2026. 6. 1 · 버전 1.0';
const _firstParagraph = '이 약관은 세대 가계부(이하 "서비스")를 이용하는 데 필요한 회사와 회원의 권리, 의무 및 책임을 정합니다.';

Future<void> _pumpPage(
  WidgetTester t,
  LegalTab tab, {
  AppTheme? theme,
  Size size = const Size(390, 844),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(fakeScope(
    fakeContainer(),
    MaterialApp(theme: materialTheme(theme ?? LightTheme()), home: LegalPage(initialTab: tab)),
  ));
  await t.settle(); // 본문 JSON asset 로드
}

Color _boxColor(WidgetTester t, Finder container) =>
    (t.widget<Container>(container).decoration! as BoxDecoration).color!;

Color _textColor(WidgetTester t, Finder text) => t.widget<Text>(text).style!.color!;

/// [text]를 감싼 가장 가까운 Container(배지)의 배경색.
Color _badgeBackground(WidgetTester t, String text) =>
    _boxColor(t, find.ancestor(of: find.text(text).first, matching: find.byType(Container)).first);

double _scrollOffset(WidgetTester t) =>
    t.widget<SingleChildScrollView>(find.byKey(const Key('legal-body'))).controller!.offset;

void main() {
  testWidgets('initialTab terms: 이용약관 탭이 선택되고 약관 본문이 보인다', (t) async {
    await _pumpPage(t, LegalTab.terms);

    expect(find.text('약관 및 정책'), findsOneWidget);
    expect(find.text(_termsTitle), findsOneWidget);
    expect(find.text(_meta), findsOneWidget);
    expect(find.text('제1조 (목적)'), findsOneWidget);
    expect(find.text(_firstParagraph), findsOneWidget);
    expect(find.text(_summaryLabel), findsNothing);
    expect(find.text(_privacyTitle), findsOneWidget); // 탭 라벨만
  });

  testWidgets('initialTab privacy: 개인정보처리방침 탭이 선택되고 요약·표·라벨값이 보인다', (t) async {
    await _pumpPage(t, LegalTab.privacy);

    expect(find.text(_privacyTitle), findsNWidgets(2)); // 탭 라벨 + 문서 제목
    expect(find.text(_termsTitle), findsNothing);
    expect(find.text(_summaryLabel), findsOneWidget);
    for (final label in ['수집 항목', '이용 목적', '보유 기간', '제3자 제공']) {
      expect(find.text(label), findsOneWidget, reason: '요약 타일은 하나씩만'); // 2×2 그리드가 칸을 겹쳐 그리지 않는다
    }
    expect(find.text('계정 · 나이대 · 소득 · 지출'), findsOneWidget);
    expect(find.text('필수'), findsNWidgets(3));
    expect(find.text('자동'), findsOneWidget);
    expect(find.text('소셜 계정 식별자, 닉네임, 이메일'), findsOneWidget);
  });

  testWidgets('탭을 바꾸면 본문이 바뀌고 스크롤이 맨 위로 간다', (t) async {
    await _pumpPage(t, LegalTab.terms, size: const Size(390, 600));

    await t.drag(find.byKey(const Key('legal-body')), const Offset(0, -400));
    await t.pumpAndSettle();
    expect(_scrollOffset(t), greaterThan(0));

    await t.tap(find.byKey(const Key('legal-tab-privacy')));
    await t.pumpAndSettle();
    expect(_scrollOffset(t), 0);
    expect(find.text(_summaryLabel), findsOneWidget);

    await t.drag(find.byKey(const Key('legal-body')), const Offset(0, -400));
    await t.pumpAndSettle();
    expect(_scrollOffset(t), greaterThan(0));

    await t.tap(find.byKey(const Key('legal-tab-terms')));
    await t.pumpAndSettle();
    expect(_scrollOffset(t), 0);
    expect(find.text(_termsTitle), findsOneWidget);
  });

  testWidgets('라이트: 핸드오프 색 표대로 그린다', (t) async {
    await _pumpPage(t, LegalTab.terms);

    expect(_boxColor(t, find.byKey(const Key('legal-tabs'))), const Color(0xFFF1ECE4)); // segBg
    expect(_boxColor(t, find.byKey(const Key('legal-tab-terms'))), const Color(0xFFFFFFFF)); // segActive
    expect(_textColor(t, find.text(_termsTitle)), const Color(0xFF2B2724)); // text
    expect(_textColor(t, find.text(_privacyTitle)), const Color(0xFFA8A099)); // 비선택 탭 textFaint
    expect(_textColor(t, find.text(_meta)), const Color(0xFFA8A099)); // textFaint
    expect(_textColor(t, find.text(_firstParagraph)), const Color(0xFF6F6862)); // body
    expect(_textColor(t, find.text('1.').first), const Color(0xFFC2BAB2)); // arrow

    await t.tap(find.byKey(const Key('legal-tab-privacy')));
    await t.pumpAndSettle();
    expect(_textColor(t, find.text('필수').first), const Color(0xFFF2603C)); // coral
    expect(_badgeBackground(t, '필수'), const Color(0xFFFEF0EB)); // coralTint
    expect(_textColor(t, find.text('자동')), const Color(0xFFA8A099)); // textFaint
    expect(_badgeBackground(t, '자동'), const Color(0xFFF1ECE4)); // segBg
    expect(_textColor(t, find.text('[담당자 이름]')), const Color(0xFFC2BAB2)); // kv 값 arrow
  });

  testWidgets('다크: 핸드오프 색 표대로 그린다', (t) async {
    await _pumpPage(t, LegalTab.terms, theme: DarkTheme());

    expect(_boxColor(t, find.byKey(const Key('legal-tabs'))), const Color(0xFF241F1B)); // segBg
    expect(_boxColor(t, find.byKey(const Key('legal-tab-terms'))), const Color(0xFF332C26)); // segActive
    expect(_textColor(t, find.text(_termsTitle)), const Color(0xFFF5F1EC)); // text
    expect(_textColor(t, find.text(_privacyTitle)), const Color(0xFF8C857D)); // 비선택 탭 textFaint
    expect(_textColor(t, find.text(_meta)), const Color(0xFF8C857D)); // textFaint
    expect(_textColor(t, find.text(_firstParagraph)), const Color(0xFFBDB5AC)); // body
    expect(_textColor(t, find.text('1.').first), const Color(0xFF5A534C)); // arrow

    await t.tap(find.byKey(const Key('legal-tab-privacy')));
    await t.pumpAndSettle();
    expect(_textColor(t, find.text('필수').first), const Color(0xFFFF8A6B)); // coral
    expect(_badgeBackground(t, '필수'), const Color(0xFF3A241C)); // coralTint
    expect(_textColor(t, find.text('자동')), const Color(0xFF8C857D)); // textFaint
    expect(_badgeBackground(t, '자동'), const Color(0xFF241F1B)); // segBg
    expect(_textColor(t, find.text('[담당자 이름]')), const Color(0xFF5A534C)); // kv 값 arrow
  });
}
