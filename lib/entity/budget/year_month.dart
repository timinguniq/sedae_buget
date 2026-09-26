/// 연·월 하나. 보고 있는 달이 이 값이다.
///
/// '이번 달'처럼 오늘과 견주는 판정은 [today]를 받아서 한다(부르는 쪽이 시계를 정한다).
class YearMonth implements Comparable<YearMonth> {
  const YearMonth._(this.year, this.month);

  /// [date]가 속한 달.
  factory YearMonth.of(DateTime date) => YearMonth._(date.year, date.month);

  final int year;

  /// 1~12.
  final int month;

  YearMonth get previous => YearMonth.of(DateTime(year, month - 1));
  YearMonth get next => YearMonth.of(DateTime(year, month + 1));

  /// 이 달 1일 0시.
  DateTime get start => DateTime(year, month);

  /// 다음 달 1일 0시(이 달에 들지 않는다).
  DateTime get end => DateTime(year, month + 1);

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  bool isCurrent(DateTime today) => this == YearMonth.of(today);

  /// 다음 달로 갈 수 있는가. 보고 있는 달은 이번 달보다 뒤로 가지 않는다.
  bool canGoNext(DateTime today) => compareTo(YearMonth.of(today)) < 0;

  /// 보고 있는 달을 부르는 이름: 이번 달이면 '이번 달', 아니면 'M월'.
  String name(DateTime today) => isCurrent(today) ? '이번 달' : '$month월';

  /// 연도까지 쓴 이름('2026년 9월').
  String get fullName => '$year년 $month월';

  /// 이 달을 보며 새 거래를 적을 때의 기본 날짜. 이번 달이면 오늘이고, 지난 달이면 그 달의
  /// 오늘과 같은 날(그 달에 그날이 없으면 말일)이다 — 적은 거래가 보고 있는 목록에 나타나게.
  DateTime draftDate(DateTime today) {
    if (isCurrent(today)) return today;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, today.day > lastDay ? lastDay : today.day);
  }

  @override
  int compareTo(YearMonth other) => year != other.year ? year - other.year : month - other.month;

  @override
  bool operator ==(Object other) => other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'YearMonth($year-$month)';
}
