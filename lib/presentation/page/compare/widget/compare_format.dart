import 'package:intl/intl.dart';

/// 만원 단위 축약 표기: 1,920,000 → '192만', 9,500 → '9,500'.
String manWon(int won) {
  if (won.abs() < 10000) return NumberFormat.decimalPattern('ko').format(won);
  return '${(won / 10000).round()}만';
}
