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
  /// 입력 규칙은 draft가 가진다. 화면은 탭·입력을 draft 연산으로 옮기기만 한다.
  late TransactionDraft _draft;
  late final TextEditingController _memo;

  /// 저장·삭제 응답을 기다리는 중이면 true. 그 사이 다시 눌러 두 번 보내지 않는다.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    // 새 거래는 보고 있는 달에 적는다(지난 달을 보며 추가하면 그 달의 거래다).
    _draft = e == null
        ? TransactionDraft.create(ref.read(selectedMonthProvider).draftDate(DateTime.now()))
        : TransactionDraft.edit(e, CategoryCatalog(ref.read(customCategoriesProvider).value ?? const []));
    _memo = TextEditingController(text: _draft.memo);
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = _draft.withMemo(_memo.text);
    if (!draft.canSave) return;
    await _send(() => ref.read(monthlyTransactionsProvider.notifier).save(draft), UserAction.save);
  }

  Future<void> _delete() => _send(
      () => ref.read(monthlyTransactionsProvider.notifier).delete(widget.existing!), UserAction.delete);

  Future<void> _send(Future<Result<Transaction>> Function() request, UserAction action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await request();
    if (mounted) setState(() => _busy = false);
    _closeOr(res, action);
  }

  /// 성공이면 화면을 닫고, 실패면 입력을 둔 채 문구만 보여준다.
  void _closeOr(Result<Transaction> res, UserAction action) {
    if (!mounted) return;
    final error = res.failureOrNull;
    if (error == null) {
      context.pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage(action, error))),
    );
  }

  /// 방금 만든 카테고리를 바로 선택한다(이 지출을 분류하려고 만든 것이므로).
  Future<void> _addCategory() async {
    final created = await CategoryEditSheet.show(context);
    if (created == null || !mounted) return;
    setState(() => _draft = _draft.pickCustom(created));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _draft.date,
      firstDate: DateTime(2020), lastDate: _draft.latestDate(DateTime.now()));
    if (picked != null) setState(() => _draft = _draft.withDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    final customs = ref.watch(customCategoriesProvider).value ?? const <CustomCategory>[];
    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 22),
        child: Column(children: [
          Row(children: [
            RoundIconButton(icon: Icons.close, onTap: () => context.pop()),
            const Spacer(),
            TypeSegmented(value: _draft.type, onChanged: (t) => setState(() => _draft = _draft.withType(t))),
            if (_draft.isEdit) ...[
              const SizedBox(width: 10),
              RoundIconButton(key: const Key('delete-button'), icon: Icons.delete_outline, onTap: _delete),
            ],
          ]),
          Expanded(child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 22),
              Center(child: _CategoryPill(label: _draft.label(CategoryCatalog(customs)))),
              const SizedBox(height: 14),
              Text('₩${won.format(_draft.amount)}',
                  textAlign: TextAlign.center,
                  style: context.typo.amountHero.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 5),
              // 가맹점/메모: 디자인의 금액 아래 한 줄이 곧 입력 필드.
              TextField(
                controller: _memo,
                textAlign: TextAlign.center,
                style: context.typo.caption1W500.copyWith(color: context.color.label.normal),
                // 전역 inputDecorationTheme의 outline 테두리가 collapsed에도 적용되므로 명시적으로 끈다.
                decoration: InputDecoration.collapsed(
                  hintText: '메모 (선택)',
                  hintStyle: context.typo.caption1W500.copyWith(color: context.color.label.assistive),
                ).copyWith(enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
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
                    Text(DateFormat('yyyy.M.d', 'ko').format(_draft.date),
                        style: context.typo.caption1W600.copyWith(color: context.color.label.alternative)),
                  ]),
                ),
              )),
              // 수입은 카테고리가 없다.
              if (_draft.hasCategory) ...[
                const SizedBox(height: 14),
                _CategoryChips(
                  selected: _draft.base,
                  selectedCustomId: _draft.customCategoryId,
                  customs: customs,
                  onPickBase: (c) => setState(() => _draft = _draft.pickBase(c)),
                  onPickCustom: (c) => setState(() => _draft = _draft.pickCustom(c)),
                  onAdd: _addCategory,
                ),
              ],
            ],
          ))),
          const SizedBox(height: 12),
          AmountKeypad(
            value: KeypadInput(_draft.amount),
            onChanged: (v) => setState(() => _draft = _draft.withAmount(v.amount)),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(
            key: const Key('save-button'),
            onPressed: _busy ? null : _save,
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
