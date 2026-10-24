import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/theme/theme.dart';

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});
  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  final _controller = PageController();
  int _page = 0;
  AgeGroup? _ageGroup;
  double _income = 3000000; // 기본 ₩3.0M

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _next() {
    if (_page == 0) {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.ease);
    }
  }

  Future<void> _finish() async {
    final res = await ref.read(userProfileProvider.notifier).save(
      UserProfile(ageGroup: _ageGroup!, monthlyIncome: _income.round()));
    if (!mounted) return;
    // 저장되면 전역 가드가 홈으로 옮긴다. 실패하면 이유를 보여주고 머문다.
    final error = res.failureOrNull;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(failureMessage(UserAction.save, error)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
        child: Column(children: [
          _ProgressBar(index: _page, count: 2),
          const SizedBox(height: 24),
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _AgeStep(selected: _ageGroup, onSelect: (g) => setState(() => _ageGroup = g)),
                _IncomeStep(income: _income, onChanged: (v) => setState(() => _income = v)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _page == 0
                  ? (_ageGroup == null ? null : _next)
                  : _finish,
              child: Text(_page == 0 ? '다음' : '시작하기'),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 2분할 세그먼트 진행 바 (h4, gap 6, 지나온 단계까지 코랄) — D2.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.index, required this.count});
  final int index; final int count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(child: Container(
          height: 4,
          decoration: BoxDecoration(
            color: i <= index ? context.color.primary.normal : context.color.line.normal,
            borderRadius: BorderRadius.circular(2)),
        )),
      ],
    ],
  );
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({required this.selected, required this.onSelect});
  final AgeGroup? selected; final ValueChanged<AgeGroup> onSelect;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const MascotDongle(size: 44, featureColor: Palette.labelNormal),
          const SizedBox(width: 12),
          Text('반가워요!', style: context.typo.pageTitle.copyWith(fontSize: 22, color: context.color.label.normal)),
        ]),
        const SizedBox(height: 8),
        Text('먼저 나이대를 알려주세요',
          style: context.typo.headline2W600.copyWith(fontWeight: context.typo.bold, color: context.color.label.normal)),
        const SizedBox(height: 5),
        Text('또래 비교를 위해 꼭 필요해요',
          style: context.typo.caption1W500.copyWith(fontSize: 13, color: context.color.label.assistive)),
        const SizedBox(height: 20),
        AgeGroupPicker(selected: selected, onSelect: onSelect),
      ]),
    );
  }
}

class _IncomeStep extends StatelessWidget {
  const _IncomeStep({required this.income, required this.onChanged});
  final double income; final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.color;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('월 소득은\n어느 정도인가요?',
          style: context.typo.pageTitle.copyWith(height: 1.3, color: c.label.normal)),
        const SizedBox(height: 9),
        Text('저축률 계산과 또래 비교에만 사용해요.',
          style: context.typo.caption1W500.copyWith(fontSize: 13, color: c.label.assistive)),
        const SizedBox(height: 38),
        IncomePicker(income: income, onChanged: onChanged),
        const SizedBox(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_outline, size: 15, color: c.label.disable)),
          const SizedBox(width: 9),
          Expanded(child: Text('소득 정보는 저축률 계산과 또래 비교에만 쓰이고, 비교는 익명 통계로만 이뤄져요.',
            style: context.typo.caption1W500.copyWith(fontSize: 11.5, height: 1.5, color: c.label.assistive))),
        ]),
      ]),
    );
  }
}
