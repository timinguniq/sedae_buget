import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/peer/peer_comparison.dart';

PeerComparison _c(int mine, int peer) => PeerComparison.of(mine: mine, peer: peer)!;

void main() {
  test('또래 값이 없으면(0·빠짐) 비교하지 않는다', () {
    expect(PeerComparison.of(mine: 50000, peer: 0), isNull);
    expect(PeerComparison.of(mine: 50000, peer: null), isNull);
  });

  // 이전에는 같은 금액이 배지에서 '또래▼0%', 비교 화면에서 '약 0원 더 ▲'로 보였다.
  test('더 쓰면 more, 덜 쓰면 less, 반올림해 0%면 similar', () {
    expect(_c(600000, 300000).direction, PeerDirection.more);
    expect(_c(270000, 300000).direction, PeerDirection.less);
    expect(_c(300000, 300000).direction, PeerDirection.similar);
    expect(_c(1004, 1000).direction, PeerDirection.similar); // +0.4%
    expect(_c(1005, 1000).direction, PeerDirection.more); // +0.5% → 1%
  });

  test('증감률은 반올림한 %다(부호와 무관하게 0에서 먼 쪽)', () {
    expect(_c(600000, 300000).percent, 100);
    expect(_c(270000, 300000).percent, -10);
    expect(_c(205, 200).percent, 3);
    expect(_c(195, 200).percent, -3);
  });

  test('50% 이상 더 쓰면 크게 넘었다', () {
    expect(_c(150, 100).strong, isTrue);
    expect(_c(149, 100).strong, isFalse);
    expect(_c(10, 100).strong, isFalse); // 덜 쓴 쪽은 아무리 차이가 커도 아니다
  });

  test('배율은 내 금액 / 또래 평균', () {
    expect(_c(150, 100).ratio, 1.5);
  });
}
