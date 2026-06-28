import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_row.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

class CategoryAnalysisPage extends ConsumerStatefulWidget {
  const CategoryAnalysisPage({super.key});

  @override
  ConsumerState<CategoryAnalysisPage> createState() => _CategoryAnalysisPageState();
}

class _CategoryAnalysisPageState extends ConsumerState<CategoryAnalysisPage> {
  bool _showPeer = false;

  @override
  Widget build(BuildContext context) {
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    final usecase = ref.read(transactionUsecaseProvider);
    final peer = ref.watch(peerStatsProvider);
    final won = NumberFormat.decimalPattern('ko');
    return DefaultLayout(
      appBar: AppBar(title: const Text('카테고리 분석')),
      child: asyncTxs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (txs) {
          final summary = usecase.categorySummary(txs);
          if (summary.isEmpty) {
            return Center(child: Text('지출이 없어요',
                style: context.typo.body2W400.copyWith(color: context.color.label.alternative)));
          }
          final entries = summary.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = entries.take(6).toList();
          final restSum = entries.skip(6).fold<int>(0, (s, e) => s + e.value);
          final labels = [...top.map((e) => e.key.label), if (restSum > 0) '기타'];
          final values = [...top.map((e) => e.value), if (restSum > 0) restSum];
          // BudgetCategory per row (null for '기타' rollup)
          final cats = [...top.map((e) => e.key), if (restSum > 0) null];
          final colors = [context.color.primary.normal, ...Palette.neutralRamp];
          final total = values.fold<int>(0, (s, v) => s + v);
          return ListView(padding: const EdgeInsets.all(20), children: [
            // 또래 비교 토글
            Row(children: [
              Text('또래 비교', style: context.typo.body2W500.copyWith(color: context.color.label.normal)),
              const Spacer(),
              Switch(value: _showPeer, onChanged: (v) => setState(() => _showPeer = v)),
            ]),
            const SizedBox(height: 12),
            Center(child: SizedBox(
              width: 180, height: 180,
              child: Stack(alignment: Alignment.center, children: [
                CategoryDonut(values: values, colors: colors),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('총지출', style: context.typo.caption1W500.copyWith(color: context.color.label.assistive)),
                  Text('₩${won.format(total)}', style: context.typo.body1W600.copyWith(color: context.color.label.normal)),
                ]),
              ]),
            )),
            const SizedBox(height: 20),
            ...List.generate(labels.length, (i) {
              final cat = cats[i];
              final peerAmt = (_showPeer && cat != null) ? peer.avgByCategory[cat] : null;
              return CategoryRow(
                  label: labels[i], amount: values[i],
                  color: colors[i % colors.length], percent: values[i] / total,
                  peerAmount: peerAmt);
            }),
          ]);
        },
      ),
    );
  }
}
