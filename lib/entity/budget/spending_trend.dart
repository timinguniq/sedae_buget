import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/viewed_month.dart';
import 'package:sedae_budget/entity/budget/year_month.dart';

/// 한 달의 지출 합계.
typedef MonthExpense = ({YearMonth month, int expense});

/// 지출 추이: 보고 있는 달까지 최근 몇 달의 달별 지출 합계.
///
/// 읽을 기간([start]·[end])을 먼저 정하고, 그 기간의 거래로 달별 합계([of])를 낸다.
class SpendingTrend {
  /// [last]까지 [length]개월(오래된 달 → [last]).
  SpendingTrend.ending(YearMonth last, {int length = 6})
      : months = [for (var m = last, i = 0; i < length; m = m.previous, i++) m].reversed.toList();

  /// 추이에 드는 달(오래된 달부터).
  final List<YearMonth> months;

  /// 읽을 거래의 기간: 첫 달 1일 이상.
  DateTime get start => months.first.start;

  /// 읽을 거래의 기간: 마지막 달 다음 달 1일 미만.
  DateTime get end => months.last.end;

  /// [transactions]의 지출을 달별로 더한다. 수입과 기간 밖의 거래는 세지 않는다.
  List<MonthExpense> of(Iterable<Transaction> transactions) => [
        for (final m in months)
          (month: m, expense: ViewedMonth.expenseOf(transactions.where((t) => m.contains(t.date)))),
      ];
}
