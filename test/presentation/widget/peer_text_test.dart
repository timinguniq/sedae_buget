import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

PeerComparison _c(int mine, [int peer = 100000]) => PeerComparison.of(mine: mine, peer: peer)!;

/// [theme]의 화면에서 [read]로 색을 고른다.
Future<T> _inTheme<T>(WidgetTester t, AppTheme theme, T Function(BuildContext) read) async {
  late T value;
  await t.pumpWidget(Theme(data: materialTheme(theme), child: Builder(builder: (context) {
    value = read(context);
    return const SizedBox();
  })));
  return value;
}

void main() {
  final more = _c(112000); // +12%
  final less = _c(90000); // −10%
  final similar = _c(100300); // +0.3% → 비슷

  test('기호와 부호 붙은 %', () {
    expect(more.arrow, '▲');
    expect(less.arrow, '▼');
    expect(similar.arrow, isNull);
    expect(more.signedPercent, '+12%');
    expect(less.signedPercent, '−10%');
  });

  // 이전에는 반올림 전에 정수인지 봐서 1.96이 '2.0배'로 보였다.
  test('배율은 소수 한 자리로 반올림한 뒤 .0이면 정수로 쓴다', () {
    expect(_c(196000).ratioText, '2배');
    expect(_c(154000).ratioText, '1.5배');
    expect(_c(150000).ratioText, '1.5배');
    expect(_c(200000).ratioText, '2배');
    expect(_c(149000).ratioText, '1.5배');
  });

  test('자리마다 문구: 홈 요약·배지·항목별 행', () {
    expect(more.heroSentence, '또래 평균보다 12% 더 썼어요');
    expect(less.heroSentence, '또래 평균보다 10% 덜 썼어요');
    expect(similar.heroSentence, '또래 평균과 비슷해요');
    expect(more.badge, '또래▲12%');
    expect(less.badge, '또래▼10%');
    expect(similar.badge, '또래와 비슷');
    expect(more.rowLabel, '+12%');
    expect(less.rowLabel, '−10%');
    expect(similar.rowLabel, '비슷');
  });

  test('인사이트: 50% 이상 더 쓰면 배율, 미만이면 %, 덜 쓰면 %, 비슷하면 비슷하게', () {
    expect(_c(150000).insightHow, '1.5배 더');
    expect(_c(104000).insightHow, '4% 더');
    expect(_c(75000).insightHow, '25% 덜');
    expect(similar.insightHow, '비슷하게');
    expect(more.insightLead, '또래보다 ');
    expect(similar.insightLead, '또래와 ');
  });

  test('비교 탭 지출 비교: 차이 금액과 방향', () {
    expect(_c(1200000, 1000000).totalFooter(), '또래보다 약 20만원 더 ▲');
    expect(_c(800000, 1000000).totalFooter(), '또래보다 약 20만원 덜 ▼');
    expect(_c(1015000, 1000000).totalFooter(), '또래보다 약 1.5만원 더 ▲');
    expect(_c(1000000, 1000000).totalFooter(), '또래와 비슷해요');
  });

  test('홈 pill: 못 읽으면 없고, 빈 달·또래 평균 없음·비교를 각각 말한다', () {
    PeerCompared compared(PeerComparison? total) => PeerCompared(
        total: total, rank: null, savings: const SavingsComparison(mine: null, peer: 20),
        totalBars: null, savingsBars: (mine: 0, peer: 1));
    expect(const PeerUnavailable().heroPill, isNull);
    expect(const PeerEmptyMonth().heroPill, (arrow: null, text: '내역을 추가하면 비교가 시작돼요'));
    expect(compared(null).heroPill, (arrow: null, text: '또래 평균 집계 중'));
    expect(compared(_c(88000)).heroPill, (arrow: '▼', text: '또래 평균보다 12% 덜 썼어요'));
  });

  test('순위: 많이 쓰는 쪽 N%와 N명 중 M등', () {
    const r = (rank: 34, total: 100, percentBelow: 66, topPercent: 34);
    expect(r.sideText, '많이 쓰는 쪽 34%');
    expect(r.topPercentText, '34%');
    expect(r.placeText, '100명 중 34등');
    expect(r.headlineLead, '또래 100명 중 내 지출은');
    expect(r.headlinePlace, (number: '34', unit: '등'));
  });

  test('저축률: 또래만큼 모으면 칭찬, 아니면 권유', () {
    expect(const SavingsComparison(mine: 20, peer: 20).verdict, '잘 모으고 있어요');
    expect(const SavingsComparison(mine: 19, peer: 20).verdict, '조금 더 모아볼까요?');
  });

  test('홈 저축률 카드의 또래 줄: 또래 평균과 한마디', () {
    expect(const SavingsComparison(mine: 20, peer: 20).peerLine, '또래 평균 20% · 잘 모으고 있어요');
    expect(const SavingsComparison(mine: null, peer: 18).peerLine, '또래 평균 18% · 조금 더 모아볼까요?');
  });

  test('리포트 인사이트 본문: 앞말, 강조할 분류, 어떻게 썼는지', () {
    expect(_c(150000).insightLine(BudgetCategory.groceries),
        (prefix: '또래보다 ', highlight: '장보기', suffix: '에\n1.5배 더 썼어요'));
    expect(less.insightLine(BudgetCategory.groceries),
        (prefix: '또래보다 ', highlight: '장보기', suffix: '에\n10% 덜 썼어요'));
    expect(similar.insightLine(BudgetCategory.groceries),
        (prefix: '또래와 ', highlight: '장보기', suffix: '에\n비슷하게 썼어요'));
    expect(noInsightText, '아직 분석할 지출이\n충분치 않아요');
  });

  test('리포트 인사이트 아랫줄: 내 금액과 또래 금액', () {
    expect(_c(120000).insightSub, '한 달 ₩120,000 · 또래는 ₩100,000');
  });

  test('비교 탭 인사이트 배너: 나이대는 보통 [분류] 지출이 또래 평균을 끌어올린다', () {
    const stats = PeerStats(
        ageGroup: AgeGroup.twenties, avgMonthlyExpense: 1000000, avgSavingsRate: 0.2,
        avgByCategory: {}, samples: []);
    expect(stats.topInsight(BudgetCategory.groceries),
        (prefix: '20대는 보통 ', highlight: '장보기', suffix: ' 지출이 또래 평균을 끌어올려요.'));
  });

  group('색조', () {
    final strongMore = _c(150000); // +50% → 크게 넘음

    testWidgets('비교 탭 항목별 행 막대: 더 썼으면 코랄, 덜 썼거나 비슷하면 흐리게', (t) async {
      final colors = await _inTheme(t, LightTheme(), (c) => [more, less, similar].map((e) => e.rowBarTone(c)).toList());
      expect(colors, [Palette.primaryNormal, Palette.labelDisable, Palette.labelDisable]);
    });

    testWidgets('홈 많이 쓴 카테고리 막대: 더 썼거나 비교가 없으면 코랄, 덜 썼거나 비슷하면 회색(다크는 다크 톤)', (t) async {
      final comparisons = [more, less, similar, null];
      final light = await _inTheme(t, LightTheme(), (c) => comparisons.map((e) => topCategoryBarTone(c, e)).toList());
      expect(light, [Palette.primaryNormal, Palette.neutral400, Palette.neutral400, Palette.primaryNormal]);
      final dark = await _inTheme(t, DarkTheme(), (c) => comparisons.map((e) => topCategoryBarTone(c, e)).toList());
      expect(dark, [Palette.primaryNormal, Palette.darkTextDisabled, Palette.darkTextDisabled, Palette.primaryNormal]);
    });

    testWidgets('분류 배지: 크게 넘으면 코랄 바탕에 흰 글씨, 틴트면 더 씀만 코랄 틴트, 아니면 바탕 없음', (t) async {
      final tones = await _inTheme(t, LightTheme(), (c) => [
            strongMore.badgeTone(c, tinted: false),
            strongMore.badgeTone(c, tinted: true),
            more.badgeTone(c, tinted: true),
            less.badgeTone(c, tinted: true),
            similar.badgeTone(c, tinted: true),
            more.badgeTone(c, tinted: false),
            less.badgeTone(c, tinted: false),
          ]);
      expect(tones, [
        (fg: Palette.staticWhite, bg: Palette.primaryNormal),
        (fg: Palette.staticWhite, bg: Palette.primaryNormal),
        (fg: Palette.primaryNormal, bg: Palette.coralTint),
        (fg: Palette.labelAlternative, bg: Palette.backgroundAlternative),
        (fg: Palette.labelAlternative, bg: Palette.backgroundAlternative),
        (fg: Palette.primaryNormal, bg: null),
        (fg: Palette.labelAlternative, bg: null),
      ]);
    });
  });
}
