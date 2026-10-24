import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/failure_message.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
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

  /// 시트가 열려 있는 동안 초안은 하나다. 다시 저장해도 같은 카테고리로 보낸다.
  late CategoryDraft _draft;
  String? _error;
  bool _saving = false;

  bool get _isEdit => _draft.isEdit;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _draft = existing == null ? CategoryDraft.create() : CategoryDraft.edit(existing);
    _name = TextEditingController(text: _draft.name)
      ..addListener(() => setState(() => _draft = _draft.withName(_name.text)));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_draft.canSave || _saving) return;
    setState(() => _saving = true);
    final res = await ref.read(customCategoriesProvider.notifier).save(_draft);
    if (!mounted) return;
    final error = res.failureOrNull;
    if (error != null) {
      setState(() {
        _error = failureMessage(UserAction.save, error);
        _saving = false;
      });
      return;
    }
    Navigator.of(context).pop((res as Success<CustomCategory>).data);
  }

  @override
  Widget build(BuildContext context) {
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
              // TextField.maxLength는 앞뒤 공백까지 세므로 쓰지 않는다. 제한과 글자 수는 CategoryName으로 센다.
              inputFormatters: const [_NameLengthLimit()],
              style: context.typo.body2W600.copyWith(color: context.color.label.normal),
              decoration: InputDecoration(
                hintText: '예) 반려동물',
                counterText: '${CategoryName.countOf(_name.text)} / ${CategoryName.maxLength}',
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
                  selected: c == _draft.base,
                  onTap: () => setState(() => _draft = _draft.pickBase(c)),
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
              onPressed: !_draft.canSave || _saving ? null : _submit,
              child: Text(_isEdit ? '저장하기' : '추가하기'),
            )),
          ]),
        ),
      ),
    );
  }
}

/// 이름 칸의 길이 제한. [LengthLimitingTextInputFormatter]가 플랫폼 기본 방식으로 막는 것과 같고, 글자 수만
/// [CategoryName]으로 센다(앞뒤 공백은 세지 않는다). 넘치는 입력(붙여넣기 포함)은 [CategoryName.fittingPrefix]까지 남긴다.
class _NameLengthLimit extends TextInputFormatter {
  const _NameLengthLimit();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (CategoryName.fits(newValue.text)) return newValue;
    final full = CategoryName.countOf(oldValue.text) == CategoryName.maxLength;
    switch (LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement()) {
      case MaxLengthEnforcement.none:
        return newValue;
      case MaxLengthEnforcement.enforced:
        // 꽉 찬 칸에 더 넣으면 그 전 값을 둔다(자르면 가운데 넣은 글자가 끝 글자를 밀어낸다).
        if (full && oldValue.selection.isCollapsed) return oldValue;
      case MaxLengthEnforcement.truncateAfterCompositionEnds:
        if (full && !oldValue.composing.isValid) return oldValue;
        // 조합 중(한글 등)인 값은 넘쳐도 받고 조합이 끝나면 자른다. 조합 중에 막으면 다음 자음이 받침으로 붙는다.
        if (newValue.composing.isValid) return newValue;
    }
    return _truncate(newValue);
  }

  /// [value]를 [CategoryName.fittingPrefix]로 자른다. 선택·조합 범위는 잘린 글 안으로 줄인다
  /// ([LengthLimitingTextInputFormatter.truncate]와 같다).
  static TextEditingValue _truncate(TextEditingValue value) {
    final text = CategoryName.fittingPrefix(value.text);
    final composing = value.composing;
    return TextEditingValue(
      text: text,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, text.length),
        extentOffset: math.min(value.selection.end, text.length),
      ),
      composing: !composing.isCollapsed && text.length > composing.start
          ? TextRange(start: composing.start, end: math.min(composing.end, text.length))
          : TextRange.empty,
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
