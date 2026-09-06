import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 온보딩 소득 슬라이더 상한 (디자인 `₩6,000,000+`).
const int kOnboardingIncomeMax = 6000000;

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

const _ageDescription = <AgeGroup, String>{
  AgeGroup.teens: '학생 · 첫 용돈 관리',
  AgeGroup.twenties: '사회초년생 · 첫 독립',
  AgeGroup.thirties: '결혼 · 내 집 마련',
  AgeGroup.forties: '자녀 교육 · 안정기',
  AgeGroup.fiftiesPlus: '노후 · 건강 관리',
};

const _ageBadge = <AgeGroup, String>{
  AgeGroup.teens: '10',
  AgeGroup.twenties: '20',
  AgeGroup.thirties: '30',
  AgeGroup.forties: '40',
  AgeGroup.fiftiesPlus: '50+',
};

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
        for (final g in AgeGroup.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _AgeCard(group: g, selected: selected == g, onTap: () => onSelect(g)),
          ),
      ]),
    );
  }
}

/// 나이대 카드: 숫자 배지 36px + 라벨 700·14.5 + 설명 500·11 + 우측 라디오 21px.
class _AgeCard extends StatelessWidget {
  const _AgeCard({required this.group, required this.selected, required this.onTap});
  final AgeGroup group; final bool selected; final VoidCallback onTap;

  static const _selectedDescription = Color(0xFFC77E66);

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final badge = _ageBadge[group]!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
        decoration: BoxDecoration(
          color: selected ? c.primary.tint : c.background.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? c.primary.normal : c.line.normal, width: 1.5)),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.primary.normal : c.background.alternative),
            child: Text(badge, style: context.typo.caption1W600.copyWith(
              fontSize: badge.length > 2 ? 12 : 13, fontWeight: context.typo.extraBold,
              color: selected ? c.static.white : c.label.alternative)),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group.label, style: context.typo.label2W600.copyWith(
              fontSize: 14.5, fontWeight: context.typo.bold, color: c.label.normal)),
            const SizedBox(height: 2),
            Text(_ageDescription[group]!, style: context.typo.caption2W500.copyWith(
              fontSize: 11, color: selected ? _selectedDescription : c.label.assistive)),
          ])),
          _Radio(selected: selected),
        ]),
      ),
    );
  }
}

/// 21px 라디오: 선택 시 코랄 채움 + 흰 점 7px, 아니면 2px 회색 링.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final c = context.color;
    return Container(
      width: 21, height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.primary.normal : null,
        border: selected ? null : Border.all(color: c.line.neutral, width: 2)),
      child: selected
          ? Container(width: 7, height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.static.white))
          : null,
    );
  }
}

class _IncomeStep extends StatelessWidget {
  const _IncomeStep({required this.income, required this.onChanged});
  final double income; final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    final c = context.color;
    final rangeStyle = context.typo.caption2W500.copyWith(fontSize: 11, color: c.label.assistive);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('월 소득은\n어느 정도인가요?',
          style: context.typo.pageTitle.copyWith(height: 1.3, color: c.label.normal)),
        const SizedBox(height: 9),
        Text('또래 평균과 비교할 때만 사용해요.',
          style: context.typo.caption1W500.copyWith(fontSize: 13, color: c.label.assistive)),
        const SizedBox(height: 38),
        Center(child: Column(children: [
          Text('₩${won.format(income.round())}',
            style: context.typo.amountDisplay.copyWith(fontSize: 38, letterSpacing: -1.2, color: c.label.normal)),
          const SizedBox(height: 5),
          Text('월 평균 실수령액', style: context.typo.caption1W600.copyWith(color: c.label.assistive)),
        ])),
        const SizedBox(height: 40),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(padding: EdgeInsets.zero),
          child: Slider(
            min: 0, max: kOnboardingIncomeMax.toDouble(), divisions: 60,
            value: income.clamp(0, kOnboardingIncomeMax.toDouble()), onChanged: onChanged),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('₩0', style: rangeStyle),
          Text('₩${won.format(kOnboardingIncomeMax)}+', style: rangeStyle),
        ]),
        const SizedBox(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_outline, size: 15, color: c.label.disable)),
          const SizedBox(width: 9),
          Expanded(child: Text('소득 정보는 기기에 안전하게 보관되고, 비교는 익명 통계로만 이뤄져요.',
            style: context.typo.caption1W500.copyWith(fontSize: 11.5, height: 1.5, color: c.label.assistive))),
        ]),
      ]),
    );
  }
}
