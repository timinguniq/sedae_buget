import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 통계를 못 읽었을 때 보여줄 문구.
const peerUnavailableText = '또래 통계를 불러오지 못했어요';

/// 또래 평균이 없을 때(집계 중) 홈 요약의 문구.
const peerPendingText = '또래 평균 집계 중';

/// 빈 달(지출 0원)에 비교 대신 보여줄 문구.
const emptyMonthText = '내역을 추가하면 비교가 시작돼요';

/// 또래 비교([PeerComparison])를 화면의 말·기호·색으로 바꾼다. 위젯은 배치만 고르고,
/// 무엇이라 말할지는 여기서 정한다(앱의 또래 비교 문구는 모두 여기 있다).
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

  /// 비교 탭 지출 비교 카드 아래 줄: '또래보다 약 20만원 더 ▲'. 금액은 [won]으로 쓴다.
  String totalFooter(String Function(int amount) won) => switch (direction) {
        PeerDirection.more => '또래보다 약 ${won(mine - peer)}원 더 ▲',
        PeerDirection.less => '또래보다 약 ${won(peer - mine)}원 덜 ▼',
        PeerDirection.similar => '또래와 비슷해요',
      };

  /// 글자색: 더 썼으면 코랄, 덜 썼거나 비슷하면 흐리게.
  Color tone(BuildContext context) => _more ? context.color.primary.normal : context.color.label.alternative;
}

extension SavingsText on SavingsComparison {
  /// 저축률 한마디: 또래만큼 모으면 칭찬, 아니면 권유.
  String get verdict => atLeastPeer ? '잘 모으고 있어요' : '조금 더 모아볼까요?';
}
