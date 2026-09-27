import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';

PeerComparison _c(int mine, [int peer = 100000]) => PeerComparison.of(mine: mine, peer: peer)!;

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
  });

  test('저축률: 또래만큼 모으면 칭찬, 아니면 권유', () {
    expect(const SavingsComparison(mine: 20, peer: 20).verdict, '잘 모으고 있어요');
    expect(const SavingsComparison(mine: 19, peer: 20).verdict, '조금 더 모아볼까요?');
  });
}
