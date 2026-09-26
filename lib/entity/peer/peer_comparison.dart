/// 또래 평균 대비 내 금액의 방향.
enum PeerDirection {
  /// 또래보다 더 씀.
  more,

  /// 또래보다 덜 씀.
  less,

  /// 반올림한 차이가 0%.
  similar,
}

/// 내 금액과 또래 평균의 비교. 화면의 모든 또래 비교(배지·막대·문장)가 이 값을 그린다.
///
/// 또래 값이 없으면(평균이 0이거나 빠짐) 비교하지 않는다 — [PeerComparison.of]가 null을 돌려준다.
class PeerComparison {
  const PeerComparison._(this.mine, this.peer);

  /// [peer]가 없거나 0이면 null.
  static PeerComparison? of({required int mine, required int? peer}) =>
      peer == null || peer <= 0 ? null : PeerComparison._(mine, peer);

  final int mine;

  /// 또래 평균. 항상 0보다 크다.
  final int peer;

  /// 또래 평균 대비 증감률(%). 반올림은 부호와 무관하게 0에서 먼 쪽이다. 음수면 덜 씀.
  int get percent => ((mine - peer) * 100 / peer).round();

  PeerDirection get direction => switch (percent) {
        > 0 => PeerDirection.more,
        < 0 => PeerDirection.less,
        _ => PeerDirection.similar,
      };

  /// 또래보다 50% 이상 더 씀(강조해서 보여줄 차이).
  bool get strong => percent >= 50;

  /// 또래 평균 대비 배율(내 금액 / 또래 평균).
  double get ratio => mine / peer;
}
