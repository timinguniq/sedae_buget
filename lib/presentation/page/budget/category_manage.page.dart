import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_edit_sheet.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 카테고리 관리 화면. [initialEditing]이 true면 편집 모드로 열린다(분석 화면의 '편집' 링크).
///
/// 기본 분류([BudgetCategory])는 또래 비교 통계의 기준이라 목록에 보이기만 하고
/// 수정·삭제할 수 없다. 추가·수정·삭제는 사용자 카테고리에만 열려 있다.
class CategoryManagePage extends ConsumerStatefulWidget {
  const CategoryManagePage({super.key, this.initialEditing = false});

  final bool initialEditing;

  @override
  ConsumerState<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage> {
  late bool _editing = widget.initialEditing;

  Future<void> _confirmDelete(CustomCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => CDialog<bool>(
        title: '카테고리를 지울까요?',
        description: "'${category.name}' 지출은 ${category.base.label}(으)로 돌아가요.",
        direction: Axis.horizontal,
        buttons: [
          CDialogButton(
            label: '취소',
            result: false,
            color: Palette.fillGrey,
            labelColor: Palette.labelNeutral),
          CDialogButton(label: '삭제', result: true),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = categoryErrorMessage(
        await ref.read(customCategoriesProvider.notifier).remove(category));
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // 서버가 이 카테고리를 쓰던 거래를 상위 기본 분류로 되돌렸으므로 목록을 다시 읽는다.
    ref.invalidate(monthlyTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final asyncCustoms = ref.watch(customCategoriesProvider);
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    return DefaultLayout(
      child: Column(children: [
        _Header(
          editing: _editing,
          onClose: context.pop,
          onDone: () => setState(() => _editing = false),
        ),
        Expanded(
          child: asyncCustoms.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('카테고리를 불러오지 못했어요: $e')),
            data: (customs) => ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              children: [
                if (!_editing) ...[const _GuideCard(), const SizedBox(height: 20)],
                _SectionHeader(
                  title: '기본 카테고리 ${BudgetCategory.values.length}',
                  trailing: _editing
                      ? const _Badge(text: '수정 · 삭제 불가')
                      : Icon(Icons.lock_outline, size: 13, color: context.color.label.disable),
                  trailingLeading: true,
                ),
                _CardList(children: [
                  for (final c in BudgetCategory.values)
                    _BaseRow(
                      category: c,
                      // 커스텀 카테고리로 분리된 거래는 빼고 센다(분석 화면 집계와 같은 기준).
                      count: asyncTxs.value
                          ?.where((t) => t.customCategoryId == null && t.categoryId == c.id)
                          .length,
                    ),
                ]),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: '내 카테고리 ${customs.length}',
                  trailing: _editing
                      ? null
                      : GestureDetector(
                          key: const Key('category-edit-toggle'),
                          onTap: () => setState(() => _editing = true),
                          child: Text('편집',
                              style: context.typo.caption1W600
                                  .copyWith(color: context.color.primary.normal)),
                        ),
                ),
                if (customs.isNotEmpty)
                  _CardList(children: [
                    for (final c in customs)
                      _CustomRow(
                        category: c,
                        editing: _editing,
                        onTap: () => CategoryEditSheet.show(context, existing: c),
                        onDelete: () => _confirmDelete(c),
                      ),
                  ]),
                const SizedBox(height: 12),
                _AddButton(
                  label: _editing ? '카테고리 추가' : '새 카테고리 추가',
                  onTap: () => CategoryEditSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.editing, required this.onClose, required this.onDone});
  final bool editing;
  final VoidCallback onClose;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(children: [
        GestureDetector(
          key: const Key('category-manage-close'),
          onTap: onClose,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: context.color.background.surface,
              border: Border.all(color: context.color.line.normal),
              shape: BoxShape.circle),
            child: Icon(editing ? Icons.close : Icons.chevron_left,
                size: 18, color: context.color.label.normal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(editing ? '카테고리 편집' : '카테고리 관리',
            textAlign: editing ? TextAlign.center : TextAlign.left,
            style: context.typo.heading2W700.copyWith(color: context.color.label.normal))),
        if (editing)
          GestureDetector(
            key: const Key('category-edit-done'),
            onTap: onDone,
            child: Text('완료',
                style: context.typo.label2W600.copyWith(color: context.color.primary.normal)),
          )
        else
          const SizedBox(width: 30),
      ]),
    );
  }
}

/// 기본 카테고리를 왜 못 고치는지 설명하는 잉크색 안내 카드.
class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: InkCard.colorOf(context),
        borderRadius: BorderRadius.circular(CSize.md.radius)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const MascotDongle(size: 30),
        const SizedBox(width: 11),
        Expanded(child: Text(
          '기본 카테고리는 또래 비교 통계의 기준이라 수정하거나 지울 수 없어요.\n'
          '내 카테고리는 자유롭게 추가·삭제할 수 있어요.',
          style: context.typo.caption1W400.copyWith(
              color: context.color.label.white, height: 1.5))),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.trailingLeading = false});
  final String title;
  final Widget? trailing;

  /// true면 trailing을 제목 바로 옆에 붙인다(기본 카테고리 자물쇠·배지).
  final bool trailingLeading;

  @override
  Widget build(BuildContext context) {
    final label = Text(title,
        style: context.typo.caption1W600.copyWith(color: context.color.label.assistive));
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
      child: Row(children: [
        label,
        if (trailing != null) ...[
          const SizedBox(width: 7),
          if (trailingLeading) trailing! else ...[const Spacer(), trailing!],
        ],
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: context.color.background.alternative,
          borderRadius: BorderRadius.circular(CSize.pill.radius)),
        child: Text(text,
            style: context.typo.caption2W400.copyWith(color: context.color.label.alternative)),
      );
}

/// 흰 카드 안에 행을 구분선으로 이어 붙인다.
class _CardList extends StatelessWidget {
  const _CardList({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.background.surface,
        border: Border.all(color: context.color.line.normal),
        borderRadius: BorderRadius.circular(CSize.md.radius)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, indent: 15, endIndent: 15,
              color: context.color.line.alternative),
          children[i],
        ],
      ]),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));
}

class _BaseRow extends StatelessWidget {
  const _BaseRow({required this.category, this.count});
  final BudgetCategory category;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(children: [
        _Swatch(color: category.style.color),
        const SizedBox(width: 11),
        Expanded(child: Text(category.label,
            style: context.typo.caption1W600.copyWith(color: context.color.label.normal))),
        if (count != null)
          Text('$count건',
              style: context.typo.caption2W400.copyWith(color: context.color.label.disable)),
      ]),
    );
  }
}

class _CustomRow extends StatelessWidget {
  const _CustomRow({
    required this.category,
    required this.editing,
    required this.onTap,
    required this.onDelete,
  });

  final CustomCategory category;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      child: Row(children: [
        _Swatch(color: context.color.primary.normal.withValues(alpha: 0.45)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category.name,
              style: context.typo.caption1W600.copyWith(color: context.color.label.normal)),
          const SizedBox(height: 1),
          Text('${category.base.label}에 포함${editing ? ' · 비교 반영' : ''}',
              style: context.typo.caption2W400.copyWith(color: context.color.label.assistive)),
        ])),
        if (editing)
          GestureDetector(
            key: Key('category-delete-${category.id}'),
            onTap: onDelete,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.color.primary.tint, width: 1.5)),
              child: Icon(Icons.remove, size: 13, color: context.color.primary.normal),
            ),
          )
        else
          Icon(Icons.chevron_right, size: 18, color: context.color.label.disable),
      ]),
    );
    return editing ? row : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: row);
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('category-add-button'),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: context.color.line.neutral, width: 1.5),
          borderRadius: BorderRadius.circular(CSize.md.radius)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add, size: 15, color: context.color.label.alternative),
          const SizedBox(width: 7),
          Text(label,
              style: context.typo.caption1W600.copyWith(color: context.color.label.alternative)),
        ]),
      ),
    );
  }
}
