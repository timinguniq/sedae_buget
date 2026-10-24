import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 프로필(나이대·월 소득) 수정. 설정의 프로필 카드에서 push로 열고, 고르는 방법은 온보딩과 같다.
/// 저장하면 설정으로 돌아가고, 실패하면 고른 값을 둔 채 이유를 보여준다.
class ProfileEditPage extends ConsumerWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 세션 게이트가 준비된(프로필이 있는) 뒤에 오는 화면이다. 웹 새로 고침처럼 프로필을 다시 확인하는 동안만 비어 있다.
    final saved = ref.watch(userProfileProvider).value;
    return DefaultLayout(
      child: Column(children: [
        // 헤더: 설정 화면과 같은 ‹ 원형 버튼 + 제목 800·20
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
          child: Row(children: [
            RoundIconButton(icon: Icons.chevron_left, onTap: () => context.pop()),
            const SizedBox(width: 12),
            Text('프로필 수정', style: context.typo.pageTitle.copyWith(fontSize: 20, color: context.color.label.normal)),
          ]),
        ),
        if (saved != null) Expanded(child: _ProfileForm(saved: saved)),
      ]),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.saved});
  final UserProfile saved;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late AgeGroup _ageGroup = widget.saved.ageGroup;
  late double _income = widget.saved.monthlyIncome.toDouble();

  /// 저장 응답을 기다리는 중이면 true. 그 사이 다시 눌러 두 번 보내지 않는다.
  bool _saving = false;

  UserProfile get _edited => UserProfile(ageGroup: _ageGroup, monthlyIncome: _income.round());

  /// 저장은 프로필을 '확인 중'으로 되돌리지 않아(세션 게이트가 준비됨 그대로) 가드가 화면을 옮기지 않는다.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final res = await ref.read(userProfileProvider.notifier).save(_edited);
    if (!mounted) return;
    setState(() => _saving = false);
    final error = res.failureOrNull;
    if (error == null) {
      context.pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage(UserAction.save, error))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionLabel('나이대', top: 0),
            AgeGroupPicker(selected: _ageGroup, onSelect: (g) => setState(() => _ageGroup = g)),
            const _SectionLabel('월 소득', top: 11),
            IncomePicker(income: _income, onChanged: (v) => setState(() => _income = v)),
          ]),
        ),
      ),
      // 하단 버튼: 온보딩과 같은 전체 폭 버튼
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('save-button'),
            // 바꾼 것이 없으면 저장할 것도 없다.
            onPressed: _saving || _edited == widget.saved ? null : _save,
            child: const Text('저장하기'),
          ),
        ),
      ),
    ]);
  }
}

/// 섹션 라벨: 설정 화면의 섹션 라벨과 같은 700·11 assistive, letterSpacing .5.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.top});
  final String text; final double top;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(4, top, 4, 9),
        child: Text(text, style: context.typo.caption2W600.copyWith(
          fontSize: 11, fontWeight: context.typo.bold, letterSpacing: 0.5, color: context.color.label.assistive)),
      );
}
