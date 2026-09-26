import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_feed.dart';
import 'package:sedae_budget/presentation/page/budget/widget/day_ad_banner.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/presentation/page/compare/widget/compare_format.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 내역 화면. 디자인: "내역" + 월 칩 / "이번 달 N원 · M건" / 카테고리 필터 칩 / 날짜 그룹 헤더.
class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  /// 필터 카테고리. null이면 전체.
  BudgetCategory? _filter;

  @override
  Widget build(BuildContext context) {
    // 달이 바뀌면 필터 칩 목록도 바뀌므로 필터를 '전체'로 되돌린다.
    ref.listen(selectedMonthProvider, (_, _) => setState(() => _filter = null));
    final month = ref.watch(selectedMonthProvider);
    final name = ref.watch(viewedMonthNameProvider);
    final overview = ref.watch(monthOverviewProvider);
    return DefaultLayout(
      child: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadErrorView(error: e, onRetry: ref.read(monthlyTransactionsProvider.notifier).reload),
        data: (o) {
          final m = o.month;
          final topCats = m.topCategories(4).map((e) => e.key).toList();
          // 고른 분류가 칩에서 빠지면(더 큰 지출이 생겨 상위 4개 밖으로) 필터를 푼다.
          if (!topCats.contains(_filter)) _filter = null;
          final filter = _filter;
          final filtered = filter == null ? m.transactions : m.inCategory(filter);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('내역', style: context.typo.pageTitle.copyWith(color: context.color.label.normal)),
                  _MonthChip(month: month),
                ]),
                const SizedBox(height: 4),
                Text('$name ${manWon(m.expense)}원 · ${m.expenseCount}건',
                    style: context.typo.caption1W500.copyWith(color: context.color.label.assistive)),
                const SizedBox(height: 13),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    DesignChip(
                      label: '전체',
                      style: _filter == null ? DesignChipStyle.ink : DesignChipStyle.outline,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final c in topCats) ...[
                      const SizedBox(width: 7),
                      DesignChip(
                        label: c.label,
                        style: _filter == c ? DesignChipStyle.ink : DesignChipStyle.outline,
                        onTap: () => setState(() => _filter = c),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('내역이 없어요',
                      style: context.typo.body2W400.copyWith(color: context.color.label.alternative)))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        for (final item in buildTransactionFeed(filtered))
                          switch (item) {
                            FeedDayHeader(:final day, :final isFirst) => Padding(
                                padding: EdgeInsets.only(top: isFirst ? 6 : 14, bottom: 2),
                                child: Text(dateGroupLabel(day),
                                    style: context.typo.caption1W600
                                        .copyWith(color: context.color.label.assistive)),
                              ),
                            FeedDivider() => Divider(
                                height: 1, thickness: 1, color: context.color.line.alternative),
                            FeedAdSlot(:final day) => DayAdBanner(key: ValueKey(day)),
                            FeedTransaction(:final transaction) => TransactionTile(
                                tx: transaction,
                                label: m.labelOf(transaction),
                                onTap: () => context.push(RoutePath.transactionEdit.path,
                                    extra: transaction),
                                overPeer: o.overPeer(transaction),
                              ),
                          },
                      ],
                    ),
            ),
          ]);
        },
      ),
    );
  }

}

/// 헤더 우측 월 칩 `M월 ▼` — 탭하면 이전/다음 달 선택.
class _MonthChip extends ConsumerWidget {
  const _MonthChip({required this.month});
  final YearMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prev = month.previous;
    final next = month.next;
    final canGoNext = ref.read(selectedMonthProvider.notifier).canGoNext;
    return PopupMenuButton<int>(
      key: const Key('month-chip'),
      onSelected: (d) => d < 0
          ? ref.read(selectedMonthProvider.notifier).prev()
          : ref.read(selectedMonthProvider.notifier).next(),
      itemBuilder: (_) => [
        PopupMenuItem(value: -1, child: Text('이전 달 · ${prev.month}월')),
        // 이번 달보다 뒤로는 가지 않는다.
        PopupMenuItem(value: 1, enabled: canGoNext, child: Text('다음 달 · ${next.month}월')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: context.color.background.surface,
          border: Border.all(color: context.color.line.normal),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${month.month}월', style: context.typo.caption1W600.copyWith(
              fontSize: 12.5, fontWeight: context.typo.bold, color: context.color.label.normal)),
          const SizedBox(width: 5),
          Text('▼', style: context.typo.caption2W600.copyWith(fontSize: 9, color: context.color.label.assistive)),
        ]),
      ),
    );
  }
}
