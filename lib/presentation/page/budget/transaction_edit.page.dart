import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_edit_sheet.dart';
import 'package:sedae_budget/theme/theme.dart';

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
    return DefaultLayout(
      appBar: AppBar(
        title: Text(_isEdit ? '거래 수정' : '거래 추가'),
        actions: [if (_isEdit) IconButton(
          key: const Key('delete-button'),
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref.read(monthlyTransactionsProvider.notifier).delete(widget.existing!);
            if (context.mounted) context.pop();
          })],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Expanded(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeSegmented(value: _type, onChanged: (t) => setState(() => _type = t)),
              const SizedBox(height: 20),
              Center(child: Text('₩${won.format(_amount.amount)}',
                  style: context.typo.amountDisplay.copyWith(color: context.color.label.normal))),
              const SizedBox(height: 16),
              _CategoryGrid(
                selected: _category,
                selectedCustomId: _customCategoryId,
                customs: ref.watch(customCategoriesProvider).value ?? const [],
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
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: context.color.label.neutral),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy.M.d', 'ko').format(_date),
                        style: context.typo.body2W500.copyWith(color: context.color.label.normal)),
                  ]),
                ),
              ),
              TextField(
                controller: _memo,
                style: context.typo.body2W400.copyWith(color: context.color.label.normal),
                decoration: const InputDecoration(hintText: '메모 (선택)'),
              ),
            ],
          ))),
          const SizedBox(height: 8),
          AmountKeypad(value: _amount, onChanged: (v) => setState(() => _amount = v)),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton(
            key: const Key('save-button'),
            onPressed: _save,
            child: const Text('저장'))),
        ]),
      ),
    );
  }
}

/// 기본 분류 12개 + 사용자 카테고리 + '추가' 칩.
/// 사용자 카테고리를 고르면 상위 기본 분류가 함께 정해진다(또래 비교는 그 분류로 집계).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        for (final c in BudgetCategory.values)
          _Chip(
            icon: c.style.icon,
            label: c.label,
            selected: selectedCustomId == null && c == selected,
            onTap: () => onPickBase(c),
          ),
        for (final c in customs)
          _Chip(
            icon: c.base.style.icon,
            label: c.name,
            selected: selectedCustomId == c.id,
            onTap: () => onPickCustom(c),
          ),
        GestureDetector(
          key: const Key('category-add-chip'),
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.color.primary.tint,
              border: Border.all(color: context.color.primary.normal.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(CSize.pill.radius),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: 14, color: context.color.primary.normal),
              const SizedBox(width: 4),
              Text('추가', style: context.typo.caption1W600
                  .copyWith(color: context.color.primary.normal)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.color.primary.tint : context.color.background.alternative,
          borderRadius: BorderRadius.circular(CSize.pill.radius),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14,
              color: selected ? context.color.primary.normal : context.color.label.neutral),
          const SizedBox(width: 4),
          Text(label, style: context.typo.caption1W500.copyWith(
              color: selected ? context.color.primary.normal : context.color.label.neutral)),
        ]),
      ),
    );
  }
}
