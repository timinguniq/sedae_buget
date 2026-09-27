import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

Transaction _tx(int amount, DateTime date, {TransactionType type = TransactionType.expense}) =>
    Transaction.create(amount: amount, categoryId: 1, date: date, type: type);

void main() {
  test('보고 있는 달까지 6개월이고 해가 바뀌어도 이어진다', () {
    final t = SpendingTrend.ending(YearMonth.of(DateTime(2026, 2)));
    expect(t.months.map((m) => m.toString()), [
      'YearMonth(2025-9)', 'YearMonth(2025-10)', 'YearMonth(2025-11)',
      'YearMonth(2025-12)', 'YearMonth(2026-1)', 'YearMonth(2026-2)',
    ]);
    expect(t.start, DateTime(2025, 9));
    expect(t.end, DateTime(2026, 3));
  });

  test('달별 지출 합계: 수입과 기간 밖의 거래는 세지 않고, 거래가 없는 달은 0이다', () {
    final t = SpendingTrend.ending(YearMonth.of(DateTime(2026, 9)), length: 3);
    final points = t.of([
      _tx(1000, DateTime(2026, 7, 1)),
      _tx(2000, DateTime(2026, 7, 31, 23, 59)),
      _tx(9000, DateTime(2026, 9, 3), type: TransactionType.income),
      _tx(500, DateTime(2026, 9, 30)),
      _tx(7000, DateTime(2026, 6, 30)), // 기간 밖
      _tx(7000, DateTime(2026, 10, 1)), // 기간 밖
    ]);
    expect(points.map((p) => p.month.month), [7, 8, 9]);
    expect(points.map((p) => p.expense), [3000, 0, 500]);
  });
}
