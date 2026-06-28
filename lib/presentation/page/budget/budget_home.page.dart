import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/summary_hero_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/theme/theme.dart';

class BudgetHomePage extends ConsumerWidget {
  const BudgetHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    final usecase = ref.read(transactionUsecaseProvider);

    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('yyyy년 M월', 'ko').format(month),
                  style: context.typo.caption1W500.copyWith(color: context.color.label.assistive)),
              Text('이번 달 요약', style: context.typo.heading2W700.copyWith(color: context.color.label.normal)),
            ]),
            GestureDetector(
              onTap: () => context.push(RoutePath.setting.path),
              child: const MascotDongle(size: 40)),
          ]),
          const SizedBox(height: 16),
          Expanded(child: asyncTxs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('불러오기 실패: $e', style: context.typo.body2W400)),
            data: (txs) => ListView(children: [
              SummaryHeroCard(expense: usecase.totalExpense(txs), income: usecase.totalIncome(txs)),
              const SizedBox(height: 13),
              GestureDetector(
                onTap: () => context.push(RoutePath.categoryAnalysis.path),
                child: _CategoryPreview(summary: usecase.categorySummary(txs))),
              const SizedBox(height: 13),
              Text('최근 내역', style: context.typo.label1W600.copyWith(color: context.color.label.normal)),
              if (txs.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('내역이 없어요. + 로 추가하세요',
                    style: context.typo.body2W400.copyWith(color: context.color.label.alternative))))
              else
                ...txs.take(5).map((t) => TransactionTile(tx: t,
                  onTap: () => context.push(RoutePath.transactionEdit.path, extra: t))),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.summary});
  final Map summary; // Map<BudgetCategory, int>
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(CSize.card.radius),
        border: Border.all(color: context.color.line.normal)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('카테고리 분석', style: context.typo.body1W600.copyWith(color: context.color.label.normal)),
        Text('자세히 ›', style: context.typo.caption1W500.copyWith(color: context.color.label.assistive)),
      ]),
    );
  }
}
