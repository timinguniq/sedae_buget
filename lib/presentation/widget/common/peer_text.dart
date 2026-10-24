import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/won_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 통계를 못 읽었을 때 보여줄 문구.
const peerUnavailableText = '또래 통계를 불러오지 못했어요';

/// 또래 평균이 없을 때(집계 중) 홈 요약의 문구.
const peerPendingText = '또래 평균 집계 중';

/// 빈 달(지출 0원)에 비교 대신 보여줄 문구.
const emptyMonthText = '내역을 추가하면 비교가 시작돼요';

/// 내역 타일의 또래 초과 배지(이 거래의 분류에서 보고 있는 달의 지출이 또래 평균을 넘었다).
const overPeerText = '또래보다 많이';

/// 리포트 "이달의 발견"에 말할 분류가 없을 때의 본문.
const noInsightText = '아직 분석할 지출이\n충분치 않아요';

/// 분류 배지의 글자색과 바탕색(null이면 바탕 없음).
typedef PeerBadgeTone = ({Color fg, Color? bg});

/// 인사이트 한 줄에 그릴 것: 앞말, 강조할 분류 이름, 뒷말(리포트 "이달의 발견"·비교 탭 인사이트 배너).
typedef PeerInsightLine = ({String prefix, String highlight, String suffix});

/// 또래 비교([PeerComparison])·보고 있는 달의 또래 상황([PeerStanding])·순위([PeerRank])를 화면의 말·기호·색으로 바꾼다.
/// 위젯은 배치만 고르고, 비교 결과에 따라 무엇이라 말하고 어떤 색을 쓸지는 여기서 정한다.
/// 결과와 상관없이 늘 같은 이름표('많이 쓴 카테고리'·'← 덜 씀 · 더 씀 →' 등)는 위젯에 둔다.
///
/// - 비슷은 반올림한 차이가 0%일 때다([PeerDirection.similar]). 자리마다 길이에 맞춘 말을 쓴다.
/// - 크게 넘으면(50%↑, [PeerComparison.strong]) 인사이트는 배율로 말한다.
/// - 배율은 소수 한 자리로 반올림한 뒤 .0이면 정수로 쓴다(1.96 → '2배').
extension PeerText on PeerComparison {
  bool get _more => direction == PeerDirection.more;

  /// '▲'(더)·'▼'(덜). 비슷이면 null.
  String? get arrow => switch (direction) {
        PeerDirection.more => '▲',
        PeerDirection.less => '▼',
        PeerDirection.similar => null,
      };

  /// '+12%'·'−10%'·'0%'.
  String get signedPercent => percent > 0 ? '+$percent%' : (percent < 0 ? '−${-percent}%' : '0%');

  /// 배율: '1.5배'·'2배'.
  String get ratioText {
    final rounded = (ratio * 10).round() / 10;
    return rounded == rounded.roundToDouble() ? '${rounded.round()}배' : '$rounded배';
  }

  /// 홈 요약 pill: '또래 평균보다 12% 더 썼어요'.
  String get heroSentence => switch (direction) {
        PeerDirection.more => '또래 평균보다 $percent% 더 썼어요',
        PeerDirection.less => '또래 평균보다 ${-percent}% 덜 썼어요',
        PeerDirection.similar => '또래 평균과 비슷해요',
      };

  /// 분류 배지: '또래▲12%'.
  String get badge => switch (direction) {
        PeerDirection.more => '또래▲$percent%',
        PeerDirection.less => '또래▼${-percent}%',
        PeerDirection.similar => '또래와 비슷',
      };

  /// 비교 탭 항목별 행: '+12%'·'−10%'·'비슷'.
  String get rowLabel => direction == PeerDirection.similar ? '비슷' : signedPercent;

  /// 리포트 인사이트의 앞말: '또래보다 '·'또래와 '(비슷).
  String get insightLead => direction == PeerDirection.similar ? '또래와 ' : '또래보다 ';

  /// 리포트 인사이트의 '어떻게': '1.5배 더'·'4% 더'·'25% 덜'·'비슷하게'.
  String get insightHow => switch (direction) {
        PeerDirection.more when strong => '$ratioText 더',
        PeerDirection.more => '$percent% 더',
        PeerDirection.less => '${-percent}% 덜',
        PeerDirection.similar => '비슷하게',
      };

  /// 리포트 "이달의 발견" 본문: '또래보다 ' + '장보기' + '에\n1.5배 더 썼어요'.
  /// 비슷하면 '또래와 ' + '장보기' + '에\n비슷하게 썼어요'. [category]는 차이가 가장 큰 분류다.
  PeerInsightLine insightLine(BudgetCategory category) =>
      (prefix: insightLead, highlight: category.label, suffix: '에\n$insightHow 썼어요');

  /// 리포트 인사이트의 아랫줄: '한 달 ₩120,000 · 또래는 ₩100,000'.
  String get insightSub => '한 달 ${WonText.full.of(mine)} · 또래는 ${WonText.full.of(peer)}';

  /// 비교 탭 지출 비교 카드 아래 줄: '또래보다 약 20만원 더 ▲'.
  String totalFooter() => switch (direction) {
        PeerDirection.more => '또래보다 약 ${WonText.shortWithUnit.of(mine - peer)} 더 ▲',
        PeerDirection.less => '또래보다 약 ${WonText.shortWithUnit.of(peer - mine)} 덜 ▼',
        PeerDirection.similar => '또래와 비슷해요',
      };

  /// 글자색: 더 썼으면 코랄, 덜 썼거나 비슷하면 흐리게.
  Color tone(BuildContext context) => _more ? context.color.primary.normal : context.color.label.alternative;

  /// 분류 배지 색: 크게 넘으면 코랄 바탕에 흰 글씨, 그 밖은 [tone] 글씨.
  /// [tinted](홈 "많이 쓴 카테고리")면 더 썼을 때 코랄 틴트, 아니면 회색 바탕이다.
  PeerBadgeTone badgeTone(BuildContext context, {required bool tinted}) => strong
      ? (fg: context.color.static.white, bg: context.color.primary.normal)
      : (
          fg: tone(context),
          bg: tinted ? (_more ? context.color.primary.tint : context.color.background.alternative) : null,
        );

  /// 비교 탭 항목별 행의 막대색: 더 썼으면 코랄, 덜 썼거나 비슷하면 흐리게.
  Color rowBarTone(BuildContext context) => _more ? context.color.primary.normal : context.color.label.disable;
}

/// 홈 "많이 쓴 카테고리" 막대색: 더 썼거나 또래 비교가 없으면(null) 코랄, 덜 썼거나 비슷하면 회색.
Color topCategoryBarTone(BuildContext context, PeerComparison? comparison) => comparison == null || comparison._more
    ? context.color.primary.normal
    : (context.theme.brightness == Brightness.dark ? context.color.label.disable : Palette.neutral400);

extension PeerStatsText on PeerStats {
  /// 비교 탭 인사이트 배너: '20대는 보통 ' + '장보기' + ' 지출이 또래 평균을 끌어올려요.'
  /// [top]은 또래가 가장 많이 쓰는 분류(`MonthOverview.peerTopCategory`).
  PeerInsightLine topInsight(BudgetCategory top) =>
      (prefix: '${ageGroup.label}는 보통 ', highlight: top.label, suffix: ' 지출이 또래 평균을 끌어올려요.');
}

/// 홈 요약 pill에 그릴 것: 화살표('▲'·'▼', 없으면 null)와 문구.
typedef PeerPill = ({String? arrow, String text});

extension PeerStandingText on PeerStanding {
  /// 홈 요약 pill. 또래 통계를 못 읽었으면 pill이 없다(null).
  PeerPill? get heroPill => switch (this) {
        PeerUnavailable() => null,
        PeerEmptyMonth() => (arrow: null, text: emptyMonthText),
        PeerCompared(:final total?) => (arrow: total.arrow, text: total.heroSentence),
        PeerCompared() => (arrow: null, text: peerPendingText),
      };
}

/// 순위 자리의 이름: '많이 쓰는 쪽'(리포트 타일은 이름과 값을 따로 쓴다).
const rankSideLabel = '많이 쓰는 쪽';

/// 비교 탭 순위 큰 글씨에 그릴 것: 등수와 단위(크기를 달리해 따로 그린다).
typedef PeerRankPlace = ({String number, String unit});

extension PeerRankText on PeerRank {
  /// '34%'(많이 쓰는 쪽에서).
  String get topPercentText => '$topPercent%';

  /// '많이 쓰는 쪽 34%'.
  String get sideText => '$rankSideLabel $topPercentText';

  /// '100명 중 34등'.
  String get placeText => '$total명 중 $rank등';

  /// 비교 탭 순위 머리말: '또래 100명 중 내 지출은'.
  String get headlineLead => '또래 $total명 중 내 지출은';

  /// 비교 탭 순위 큰 글씨: '34' + '등'.
  PeerRankPlace get headlinePlace => (number: '$rank', unit: '등');
}

extension SavingsText on SavingsComparison {
  /// 저축률 한마디: 또래만큼 모으면 칭찬, 아니면 권유.
  String get verdict => atLeastPeer ? '잘 모으고 있어요' : '조금 더 모아볼까요?';

  /// 홈 저축률 카드의 또래 줄: '또래 평균 20% · 잘 모으고 있어요'.
  String get peerLine => '또래 평균 $peer% · $verdict';
}
