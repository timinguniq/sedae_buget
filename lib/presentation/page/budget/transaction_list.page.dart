import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    return DefaultLayout(
      appBar: AppBar(title: const Text('내역')),
      child: asyncTxs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (txs) => txs.isEmpty
          ? Center(child: Text('내역이 없어요', style: context.typo.body2W400.copyWith(color: context.color.label.alternative)))
          : ListView(children: txs.map((t) => TransactionTile(tx: t,
              onTap: () => context.push(RoutePath.transactionEdit.path, extra: t))).toList()),
      ),
    );
  }
}
