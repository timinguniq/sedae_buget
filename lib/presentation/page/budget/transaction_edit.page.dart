import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_edit_sheet.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 지출 입력. 디자인: ✕ 원형 + 트랙형 세그먼트 / 카테고리 pill + 금액 800·42 + 메모 / 가로 스크롤 칩 / 키패드 / 저장하기.
class TransactionEditPage extends ConsumerStatefulWidget {
  const TransactionEditPage({super.key, this.existing});
  final Transaction? existing;
  @override
  ConsumerState<TransactionEditPage> createState() => _State();
}

class _State extends ConsumerState<TransactionEditPage> {
  late KeypadInput _amount;
  late TransactionType _type;
  late BudgetCategory _category;

  /// 선택한 사용자 카테고리. null이면 [_category] 기본 분류 그대로.
  String? _customCategoryId;
  late DateTime _date;
  late final TextEditingController _memo;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = KeypadInput(e?.amount ?? 0);
    _type = e?.type ?? TransactionType.expense;
    _category = e == null ? BudgetCategory.food : BudgetCategory.fromId(e.categoryId);
    _customCategoryId = e?.customCategoryId;
    _date = e?.date ?? DateTime.now();
    _memo = TextEditingController(text: e?.memo ?? '');
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amount.amount <= 0) return;
    final notifier = ref.read(monthlyTransactionsProvider.notifier);
    final memo = _memo.text.trim().isEmpty ? null : _memo.text.trim();
    if (_isEdit) {
      await notifier.edit(widget.existing!.copyWith(
        amount: _amount.amount, categoryId: _category.id, date: _date, type: _type, memo: memo,
        customCategoryId: _customCategoryId));
    } else {
      await notifier.add(amount: _amount.amount, categoryId: _category.id, date: _date, type: _type,
        memo: memo, customCategoryId: _customCategoryId);
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    await ref.read(monthlyTransactionsProvider.notifier).delete(widget.existing!);
    if (mounted) context.pop();
  }

  /// 방금 만든 카테고리를 바로 선택한다(이 지출을 분류하려고 만든 것이므로).
  Future<void> _addCategory() async {
    final created = await CategoryEditSheet.show(context);
    if (created == null || !mounted) return;
    setState(() {
      _category = created.base;
      _customCategoryId = created.id;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    final customs = ref.watch(customCategoriesProvider).value ?? const <CustomCategory>[];
    // 방금 만든 카테고리는 목록 갱신 전일 수 있어 없으면 기본 분류 이름으로.
    final custom = customs.cast<CustomCategory?>().firstWhere(
        (c) => c!.id == _customCategoryId, orElse: () => null);
    final selectedLabel = custom?.name ?? _category.label;
    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
        child: Column(children: [
          Row(children: [
            RoundIconButton(icon: Icons.close, onTap: () => context.pop()),
            const Spacer(),
            TypeSegmented(value: _type, onChanged: (t) => setState(() => _type = t)),
            if (_isEdit) ...[
              const SizedBox(width: 10),
              RoundIconButton(key: const Key('delete-button'), icon: Icons.delete_outline, onTap: _delete),
            ],
          ]),
          Expanded(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              Center(child: _CategoryPill(label: selectedLabel)),
              const SizedBox(height: 14),
              Text('₩${won.format(_amount.amount)}',
                  textAlign: TextAlign.center,
                  style: context.typo.amountHero.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 5),
              // 가맹점/메모: 디자인의 금액 아래 한 줄이 곧 입력 필드.
              TextField(
                controller: _memo,
                textAlign: TextAlign.center,
                style: context.typo.caption1W500.copyWith(color: context.color.label.normal),
                decoration: InputDecoration.collapsed(
                  hintText: '메모 (선택)',
                  hintStyle: context.typo.caption1W500.copyWith(color: context.color.label.assistive),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(CSize.pill.radius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: context.color.label.assistive),
                    const SizedBox(width: 6),
                    Text(DateFormat('yyyy.M.d', 'ko').format(_date),
                        style: context.typo.caption1W600.copyWith(color: context.color.label.alternative)),
                  ]),
                ),
              )),
              const SizedBox(height: 14),
              _CategoryChips(
                selected: _category,
                selectedCustomId: _customCategoryId,
                customs: customs,
                onPickBase: (c) => setState(() {
                  _category = c;
                  _customCategoryId = null;
                }),
                onPickCustom: (c) => setState(() {
                  _category = c.base;
                  _customCategoryId = c.id;
                }),
                onAdd: _addCategory,
              ),
            ],
          ))),
          const SizedBox(height: 12),
          AmountKeypad(value: _amount, onChanged: (v) => setState(() => _amount = v)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(
            key: const Key('save-button'),
            onPressed: _save,
            child: const Text('저장하기'))),
        ]),
      ),
    );
  }
}

/// 선택 카테고리 pill: 코랄 tint 배경 + 7px 코랄 점 + 이름 700·12 코랄.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: context.color.primary.tint,
        borderRadius: BorderRadius.circular(CSize.pill.radius),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: context.color.primary.normal, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: context.typo.caption1W600.copyWith(
            fontWeight: context.typo.bold, color: context.color.primary.normal)),
      ]),
    );
  }
}

/// 기본 분류 12개 + 사용자 카테고리 + '추가' 칩 — 가로 스크롤 한 줄.
/// 사용자 카테고리를 고르면 상위 기본 분류가 함께 정해진다(또래 비교는 그 분류로 집계).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.selectedCustomId,
    required this.customs,
    required this.onPickBase,
    required this.onPickCustom,
    required this.onAdd,
  });

  final BudgetCategory selected;
  final String? selectedCustomId;
  final List<CustomCategory> customs;
  final ValueChanged<BudgetCategory> onPickBase;
  final ValueChanged<CustomCategory> onPickCustom;
  final VoidCallback onAdd;

  static const _chipPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 8);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final c in BudgetCategory.values) ...[
          DesignChip(
            label: c.label,
            padding: _chipPadding,
            style: selectedCustomId == null && c == selected ? DesignChipStyle.coral : DesignChipStyle.outline,
            onTap: () => onPickBase(c),
          ),
          const SizedBox(width: 7),
        ],
        for (final c in customs) ...[
          DesignChip(
            label: c.name,
            padding: _chipPadding,
            style: selectedCustomId == c.id ? DesignChipStyle.coral : DesignChipStyle.outline,
            onTap: () => onPickCustom(c),
          ),
          const SizedBox(width: 7),
        ],
        GestureDetector(
          key: const Key('category-add-chip'),
          onTap: onAdd,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.color.primary.tint,
              border: Border.all(color: context.color.primary.normal.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(CSize.pill.radius),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: 12, color: context.color.primary.normal),
              const SizedBox(width: 4),
              Text('추가', style: context.typo.caption1W600.copyWith(
                  fontSize: 11.5, fontWeight: context.typo.bold, color: context.color.primary.normal)),
            ]),
          ),
        ),
      ]),
    );
  }
}
