import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/category_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 카테고리 추가·수정 바텀시트. [existing]이 null이면 추가.
/// 저장에 성공하면 저장된 카테고리로 닫힌다(취소·실패면 null).
class CategoryEditSheet extends ConsumerStatefulWidget {
  const CategoryEditSheet({super.key, this.existing});

  final CustomCategory? existing;

  static Future<CustomCategory?> show(BuildContext context, {CustomCategory? existing}) =>
      showModalBottomSheet<CustomCategory>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CategoryEditSheet(existing: existing),
      );

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _name;
  late BudgetCategory _base;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '')
      ..addListener(() => setState(() {}));
    _base = widget.existing?.base ?? BudgetCategory.etc;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final notifier = ref.read(customCategoriesProvider.notifier);
    final res = widget.existing == null
        ? await notifier.add(name: name, base: _base)
        : await notifier.edit(widget.existing!, name: name, base: _base);
    if (!mounted) return;
    final error = categoryErrorMessage(res);
    if (error != null) {
      setState(() {
        _error = error;
        _saving = false;
      });
      return;
    }
    Navigator.of(context).pop((res as Success<CustomCategory>).data);
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.color.background.normal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                color: context.color.line.neutral,
                borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 16),
            Text(_isEdit ? '카테고리 수정' : '카테고리 추가',
                style: context.typo.headline1W600.copyWith(color: context.color.label.normal)),
            const SizedBox(height: 5),
            Text('내가 만든 카테고리는 언제든 삭제할 수 있어요.',
                style: context.typo.caption1W400.copyWith(color: context.color.label.assistive)),
            const SizedBox(height: 20),
            _FieldLabel(text: '이름'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('category-name-field'),
              controller: _name,
              autofocus: !_isEdit,
              maxLength: CustomCategory.maxNameLength,
              inputFormatters: [LengthLimitingTextInputFormatter(CustomCategory.maxNameLength)],
              style: context.typo.body2W600.copyWith(color: context.color.label.normal),
              decoration: InputDecoration(
                hintText: '예) 반려동물',
                counterText: '${_name.text.length} / ${CustomCategory.maxNameLength}',
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _FieldLabel(text: '상위 카테고리'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.color.primary.normal,
                  borderRadius: BorderRadius.circular(CSize.pill.radius)),
                child: Text('필수',
                    style: context.typo.caption2W600.copyWith(color: context.color.label.white)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('또래 비교 통계는 기본 카테고리 기준이라, 어디에 넣을지 골라주세요.',
                style: context.typo.caption2W400.copyWith(color: context.color.label.assistive)),
            const SizedBox(height: 10),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final c in BudgetCategory.values)
                _BaseChip(
                  category: c,
                  selected: c == _base,
                  onTap: () => setState(() => _base = c),
                ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: context.typo.caption1W500.copyWith(color: context.color.status.destructive)),
            ],
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton(
              key: const Key('category-submit-button'),
              onPressed: name.isEmpty || _saving ? null : _submit,
              child: Text(_isEdit ? '저장하기' : '추가하기'),
            )),
          ]),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: context.typo.caption1W600.copyWith(color: context.color.label.alternative));
}

class _BaseChip extends StatelessWidget {
  const _BaseChip({required this.category, required this.selected, required this.onTap});
  final BudgetCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? context.color.primary.normal : context.color.background.surface,
          border: Border.all(
            color: selected ? context.color.primary.normal : context.color.line.normal),
          borderRadius: BorderRadius.circular(CSize.md.radius),
        ),
        child: Text(category.label,
            style: context.typo.caption1W500.copyWith(
                color: selected ? context.color.label.white : context.color.label.alternative)),
      ),
    );
  }
}
