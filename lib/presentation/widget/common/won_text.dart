import 'package:intl/intl.dart';

/// 금액(원)을 화면에 쓰는 방식. 자리마다 디자인이 정한 종류 하나를 고르고, 쉼표·단위·반올림·음수 기호는
/// 여기서만 정한다(앱의 금액 표기는 모두 여기 있다).
///
/// - 음수는 유니코드 마이너스 `−`를 맨 앞에 쓴다: `−₩500,000`·`−1.5만`.
/// - 짧게: 1만 미만은 쉼표 그대로(`9,300`), 100만 미만은 만 단위 소수 한 자리(`1.5만`, `.0`은 뗀다),
///   100만 이상은 만 단위 반올림(`192만`), 1억 이상은 억 단위 소수 한 자리(`2.5억`).
enum WonText {
  /// `₩1,920,000`: 홈 총지출·많이 쓴 카테고리·리포트·입력·온보딩.
  full,

  /// `1,920,000`: 분석 행.
  plain,

  /// `+6,800`·`−6,800`: 거래. 양수에도 부호를 붙인다.
  signed,

  /// `192만`·`1.5만`·`9,300`: 좁은 자리(비교 막대·분석 합계·세대 차트).
  short,

  /// `192만원`·`1.5만원`·`9,300원`: 문장 속(내역 머리·비교 아래 줄).
  shortWithUnit;

  /// [amount]원을 이 방식으로 쓴다.
  String of(int amount) {
    final sign = amount < 0 ? '−' : (this == signed && amount > 0 ? '+' : '');
    final abs = amount.abs();
    return sign +
        switch (this) {
          full => '₩${_digits.format(abs)}',
          plain || signed => _digits.format(abs),
          short => _short(abs),
          shortWithUnit => '${_short(abs)}원',
        };
  }

  static final _digits = NumberFormat.decimalPattern('ko');

  static String _short(int abs) {
    if (abs < 10000) return _digits.format(abs);
    if (abs < 1000000) return '${_oneDecimal(abs, 10000)}만';
    final man = (abs + 5000) ~/ 10000;
    if (man < 10000) return '$man만';
    return '${_oneDecimal(abs, 100000000)}억';
  }

  /// [abs]를 [unit] 단위 소수 한 자리로 반올림하고 `.0`은 뗀다. 정수로 셈해 .x5를 올린다
  /// (14,500원 → 1.5만. 이진 소수 1.45는 1.4499…라 `toStringAsFixed`는 내렸다).
  static String _oneDecimal(int abs, int unit) {
    final tenths = (abs * 10 + unit ~/ 2) ~/ unit;
    return tenths % 10 == 0
        ? '${tenths ~/ 10}'
        : '${tenths ~/ 10}.${tenths % 10}';
  }
}
