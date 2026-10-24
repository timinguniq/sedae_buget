import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/age_group_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 나이대 고르기: 나이대마다 카드 한 장(간격 9). 온보딩과 프로필 수정이 함께 쓴다.
class AgeGroupPicker extends StatelessWidget {
  const AgeGroupPicker({super.key, required this.selected, required this.onSelect});
  final AgeGroup? selected; final ValueChanged<AgeGroup> onSelect;
  @override
  Widget build(BuildContext context) => Column(children: [
    for (final g in AgeGroup.values)
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _AgeCard(group: g, selected: selected == g, onTap: () => onSelect(g)),
      ),
  ]);
}

/// 나이대 카드: 숫자 배지 36px + 라벨 700·14.5 + 설명 500·11 + 우측 라디오 21px.
class _AgeCard extends StatelessWidget {
  const _AgeCard({required this.group, required this.selected, required this.onTap});
  final AgeGroup group; final bool selected; final VoidCallback onTap;

  static const _selectedDescription = Color(0xFFC77E66);

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final badge = group.badge;
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
            Text(group.lifeStage, style: context.typo.caption2W500.copyWith(
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
