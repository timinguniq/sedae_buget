import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';
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
    await ref.read(userProfileProvider.notifier).save(
      UserProfile(ageGroup: _ageGroup!, monthlyIncome: _income.round()));
    if (mounted) context.go(RoutePath.budgetHome.path);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(children: [
          _ProgressDots(index: _page, count: 2),
          const SizedBox(height: 8),
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

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.index, required this.count});
  final int index; final int count;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(count, (i) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: i == index ? 20 : 7, height: 7,
      decoration: BoxDecoration(
        color: i == index ? context.color.primary.normal : context.color.line.normal,
        borderRadius: BorderRadius.circular(4)),
    )),
  );
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({required this.selected, required this.onSelect});
  final AgeGroup? selected; final ValueChanged<AgeGroup> onSelect;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const MascotDongle(size: 64),
        const SizedBox(height: 16),
        Text('나이대를 알려주세요', style: context.typo.heading2W700.copyWith(color: context.color.label.normal)),
        const SizedBox(height: 6),
        Text('또래 비교에 사용해요', style: context.typo.body2W400.copyWith(color: context.color.label.alternative)),
        const SizedBox(height: 20),
        ...AgeGroup.values.map((g) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onSelect(g),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                color: selected == g ? context.color.primary.normal.withValues(alpha: 0.08) : context.color.background.surface,
                borderRadius: BorderRadius.circular(CSize.card.radius),
                border: Border.all(color: selected == g ? context.color.primary.normal : context.color.line.normal,
                    width: selected == g ? 2 : 1)),
              child: Text(g.label, style: context.typo.body1W600.copyWith(
                color: selected == g ? context.color.primary.strong : context.color.label.normal)),
            ),
          ),
        )),
      ]),
    );
  }
}

class _IncomeStep extends StatelessWidget {
  const _IncomeStep({required this.income, required this.onChanged});
  final double income; final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const MascotDongle(size: 64),
        const SizedBox(height: 16),
        Text('월 소득은 어느 정도인가요?', style: context.typo.heading2W700.copyWith(color: context.color.label.normal)),
        const SizedBox(height: 20),
        Text('₩${won.format(income.round())}', style: context.typo.amountDisplay.copyWith(color: context.color.primary.strong)),
        Slider(min: 0, max: 10000000, divisions: 100, value: income, onChanged: onChanged),
        const SizedBox(height: 8),
        Text('소득 정보는 기기에만 저장되며 또래 평균 비교에만 사용됩니다.',
          style: context.typo.caption1W400.copyWith(color: context.color.label.assistive)),
      ]),
    );
  }
}
