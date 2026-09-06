import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final asyncBreakdown = ref.watch(categoryBreakdownProvider);
    final asyncPeer = ref.watch(peerStatsProvider);
    final won = NumberFormat.decimalPattern('ko');
    return DefaultLayout(
      appBar: AppBar(title: const Text('카테고리 분석')),
      child: asyncPeer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('또래 통계 실패: $e')),
        data: (peer) => asyncBreakdown.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (breakdown) {
          if (breakdown.isEmpty) {
            return Center(child: Text('지출이 없어요',
                style: context.typo.body2W400.copyWith(color: context.color.label.alternative)));
          }
          final top = breakdown.take(6).toList();
          final restSum = breakdown.skip(6).fold<int>(0, (s, e) => s + e.amount);
          final labels = [
            ...top.map((e) => e.custom?.name ?? e.base.label),
            if (restSum > 0) '기타',
          ];
          final values = [...top.map((e) => e.amount), if (restSum > 0) restSum];
          // 또래 평균이 붙는 행은 기본 분류 행뿐이다('기타' 롤업·커스텀 카테고리는 null).
          final cats = [
            ...top.map((e) => e.custom == null ? e.base : null),
            if (restSum > 0) null,
          ];
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
            // 카테고리 개수 + 편집 진입(디자인: 분석 화면 → 카테고리 편집)
            Row(children: [
              Text('카테고리 ${breakdown.length}개',
                  style: context.typo.caption1W600.copyWith(color: context.color.label.assistive)),
              const Spacer(),
              GestureDetector(
                key: const Key('category-manage-link'),
                onTap: () => context.push(RoutePath.categoryManage.path, extra: true),
                child: Text('편집',
                    style: context.typo.caption1W600.copyWith(color: context.color.primary.normal)),
              ),
            ]),
            const SizedBox(height: 4),
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
      ),
    );
  }
}
