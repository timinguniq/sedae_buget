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
    final month = ref.watch(selectedMonthProvider);
    final asyncBreakdown = ref.watch(categoryBreakdownProvider);
    final asyncPeer = ref.watch(peerStatsProvider);
    return DefaultLayout(
      child: Column(children: [
        _Header(
          month: month,
          onPrev: () => ref.read(selectedMonthProvider.notifier).prev(),
          onNext: () => ref.read(selectedMonthProvider.notifier).next(),
        ),
        Expanded(child: asyncPeer.when(
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
          // 첫 조각은 코랄, 나머지는 밝기별 램프(다크는 darkRamp).
          final ramp = context.theme.brightness == Brightness.dark ? Palette.darkRamp : Palette.neutralRamp;
          final colors = List<Color>.generate(values.length,
              (i) => i == 0 ? context.color.primary.normal : ramp[(i - 1) % ramp.length]);
          final total = values.fold<int>(0, (s, v) => s + v);
          return ListView(padding: const EdgeInsets.fromLTRB(22, 6, 22, 20), children: [
            Center(child: SizedBox(
              width: 170, height: 170,
              child: Stack(alignment: Alignment.center, children: [
                CategoryDonut(values: values, colors: colors, size: 170, stroke: 36),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${month.month}월 총지출',
                      style: context.typo.caption2W600.copyWith(fontSize: 11, color: context.color.label.assistive)),
                  Text(_compactWon(total),
                      style: context.typo.amountDisplaySmall.copyWith(fontSize: 23, color: context.color.label.normal)),
                ]),
              ]),
            )),
            const SizedBox(height: 16),
            // 또래 비교 토글 (디자인 42×24 코랄 토글 — 테마 Switch를 축소)
            Row(children: [
              Text('또래 평균과 비교',
                  style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: context.color.label.normal)),
              const Spacer(),
              SizedBox(height: 24, child: FittedBox(
                child: Switch(value: _showPeer, onChanged: (v) => setState(() => _showPeer = v)))),
            ]),
            const SizedBox(height: 13),
            // 카테고리 개수 + 편집 진입(디자인: 분석 화면 → 카테고리 편집)
            Row(children: [
              Text('카테고리 ${breakdown.length}개',
                  style: context.typo.caption2W600.copyWith(fontSize: 11.5, color: context.color.label.assistive)),
              const Spacer(),
              GestureDetector(
                key: const Key('category-manage-link'),
                onTap: () => context.push(RoutePath.categoryManage.path, extra: true),
                child: Text('편집',
                    style: context.typo.caption2W600.copyWith(fontSize: 11.5, color: context.color.primary.normal)),
              ),
            ]),
            const SizedBox(height: 1),
            ...List.generate(labels.length, (i) {
              final cat = cats[i];
              final peerAmt = (_showPeer && cat != null) ? peer.avgByCategory[cat] : null;
              return CategoryRow(
                  label: labels[i], amount: values[i],
                  color: colors[i], percent: values[i] / total,
                  peerAmount: peerAmt);
            }),
          ]);
        },
        ),
        )),
      ]),
    );
  }
}

/// ‹ 원형 버튼 + "카테고리 분석" + `‹ YYYY.MM ›` 월 네비게이터.
class _Header extends StatelessWidget {
  const _Header({required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final arrow = context.typo.caption1W600.copyWith(fontWeight: context.typo.bold, color: context.color.label.disable);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(children: [
        RoundIconButton(icon: Icons.chevron_left, onTap: () => context.pop()),
        Expanded(child: Center(child: Text('카테고리 분석',
            style: context.typo.body1W600.copyWith(fontWeight: context.typo.extraBold, color: context.color.label.normal)))),
        Row(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(key: const Key('month-prev'), onTap: onPrev, behavior: HitTestBehavior.opaque,
              child: Padding(padding: const EdgeInsets.all(4), child: Text('‹', style: arrow))),
          Text(DateFormat('yyyy.MM').format(month),
              style: context.typo.caption1W600.copyWith(fontWeight: context.typo.bold, color: context.color.label.normal)),
          GestureDetector(key: const Key('month-next'), onTap: onNext, behavior: HitTestBehavior.opaque,
              child: Padding(padding: const EdgeInsets.all(4), child: Text('›', style: arrow))),
        ]),
      ]),
    );
  }
}

/// 축약 원화: 1,920,000 → `192만`, 14,000 → `1.4만`, 9,300 → `9,300원`, 250,000,000 → `2.5억`.
String _compactWon(int v) {
  String trim(String s) => s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  if (v >= 100000000) return '${trim((v / 100000000).toStringAsFixed(1))}억';
  if (v >= 10000) {
    final man = v / 10000;
    return '${man >= 100 ? man.round().toString() : trim(man.toStringAsFixed(1))}만';
  }
  return '${NumberFormat.decimalPattern('ko').format(v)}원';
}
