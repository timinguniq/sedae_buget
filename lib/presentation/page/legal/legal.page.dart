import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/page/legal/legal.view_model.dart';
import 'package:sedae_budget/presentation/page/legal/legal_content.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 약관 및 정책 화면: 이용약관·개인정보처리방침 탭. 설정과 로그인 화면에서 push로 연다(세션 가드 면제).
/// 수치·색은 디자인 핸드오프(docs/design/design_handoff_legal/README.md)의 표를 따른다.
class LegalPage extends ConsumerStatefulWidget {
  const LegalPage({super.key, required this.initialTab});

  final LegalTab initialTab;

  @override
  ConsumerState<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends ConsumerState<LegalPage> {
  late LegalTab _tab = widget.initialTab;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// 탭을 바꾸면 본문 스크롤을 맨 위로 되돌린다.
  void _select(LegalTab tab) {
    if (tab == _tab) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _tab = tab);
  }

  /// 연 화면으로 돌아간다. 웹에서 주소로 바로 열어 돌아갈 화면이 없으면 홈으로 보내고,
  /// 실제 행선지(로그인·온보딩·연결 안 됨·홈)는 전역 가드(sessionRedirect)가 정한다.
  void _close() => context.canPop() ? context.pop() : context.go(RoutePath.budgetHome.path);

  @override
  Widget build(BuildContext context) {
    final colors = _LegalColors.of(context);
    final content = ref.watch(legalContentProvider).value;
    return DefaultLayout(
      child: Column(children: [
        // 헤더: 설정 화면과 같은 ‹ 원형 버튼 + "약관 및 정책" 800·20
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
          child: Row(children: [
            RoundIconButton(icon: Icons.chevron_left, onTap: _close),
            const SizedBox(width: 12),
            Text('약관 및 정책', style: context.typo.pageTitle.copyWith(fontSize: 20, color: colors.text)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: _SegmentedTabs(value: _tab, onChanged: _select, colors: colors),
        ),
        Expanded(
          child: content == null
              ? const SizedBox.shrink()
              : _DocumentView(document: content.of(_tab), meta: content.meta, controller: _scroll, colors: colors),
        ),
      ]),
    );
  }
}

/// 세그먼트 탭: segBg r12 p3 / 아이템 세로 9 r9 / 선택 segActive + 그림자 0 1 3 rgba(43,39,36,.10) 700·12.5 / 비선택 600·12.5 textFaint
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.value, required this.onChanged, required this.colors});

  final LegalTab value;
  final ValueChanged<LegalTab> onChanged;
  final _LegalColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('legal-tabs'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.segBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (final tab in LegalTab.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab),
              behavior: HitTestBehavior.opaque,
              child: Container(
                key: Key('legal-tab-${tab.name}'),
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: tab == value
                    ? BoxDecoration(
                        color: colors.segActive,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [BoxShadow(color: Color(0x1A2B2724), offset: Offset(0, 1), blurRadius: 3)],
                      )
                    : null,
                child: Text(
                  tab.label,
                  style: tab == value
                      ? context.typo.caption1W600.copyWith(fontSize: 12.5, fontWeight: context.typo.bold, color: colors.text)
                      : context.typo.caption1W600.copyWith(fontSize: 12.5, color: colors.textFaint),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 문서 본문(스크롤). 제목·메타 → (소개·요약) → 섹션 목록. 섹션 사이 22, 섹션 안 요소 사이 8.
class _DocumentView extends StatelessWidget {
  const _DocumentView({
    required this.document,
    required this.meta,
    required this.controller,
    required this.colors,
  });

  final LegalDocument document;
  final String meta;
  final ScrollController controller;
  final _LegalColors colors;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final intro = document.intro;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        key: const Key('legal-body'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(document.title, style: typo.pageTitle.copyWith(fontSize: 19, letterSpacing: -0.4, color: colors.text)),
          const SizedBox(height: 5),
          Text(meta, style: typo.caption1W500.copyWith(fontSize: 11.5, color: colors.textFaint)),
          if (intro != null) ...[
            const SizedBox(height: 14),
            _paragraph(context, intro),
          ],
          if (document.summary.isEmpty)
            const SizedBox(height: 22)
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
              child: Text('한눈에 보기', style: typo.caption2W600.copyWith(
                fontSize: 11, fontWeight: typo.bold, letterSpacing: 0.5, color: colors.textFaint)),
            ),
            _summaryGrid(context, document.summary),
            const SizedBox(height: 24),
          ],
          for (final (i, section) in document.sections.indexed) ...[
            if (i > 0) const SizedBox(height: 22),
            _section(context, section),
          ],
        ]),
      ),
    );
  }

  /// p: 500·12.5 h1.7 body
  Widget _paragraph(BuildContext context, String text) =>
      Text(text, style: context.typo.caption1W500.copyWith(fontSize: 12.5, height: 1.7, color: colors.body));

  /// 2×2 그리드, gap 8. 타일: surface + 1px border + r14, padding 11/12.
  Widget _summaryGrid(BuildContext context, List<LegalSummaryItem> items) {
    Widget tile(LegalSummaryItem item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.label, style: context.typo.caption2W600.copyWith(fontSize: 10.5, color: colors.textFaint)),
            const SizedBox(height: 4),
            Text(item.value, style: context.typo.caption1W600.copyWith(
              fontSize: 12.5, fontWeight: context.typo.bold, height: 1.4, color: colors.text)),
          ]),
        );
    return Column(children: [
      for (var i = 0; i < items.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 8),
        // 한 줄의 두 타일을 같은 높이로(스크롤 안이라 높이가 무한해서 IntrinsicHeight로 재야 stretch가 된다).
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: tile(items[i])),
            const SizedBox(width: 8),
            Expanded(child: i + 1 < items.length ? tile(items[i + 1]) : const SizedBox.shrink()),
          ]),
        ),
      ],
    ]);
  }

  /// 제목 700·13.5 + 블록들(사이 8)
  Widget _section(BuildContext context, LegalSection section) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.heading, style: context.typo.sectionTitle.copyWith(color: colors.text)),
          for (final block in section.blocks) ...[
            const SizedBox(height: 8),
            switch (block) {
              LegalParagraph(:final text) => _paragraph(context, text),
              LegalNumberedList(:final items) => _numberedList(context, items),
              LegalTable(:final rows) => _card([for (final r in rows) _tableRow(context, r)]),
              LegalKeyValues(:final rows) => _card([for (final r in rows) _keyValueRow(context, r)]),
            },
          ],
        ],
      );

  /// ol: 항목 사이 5, 번호(폭 12, 700 arrow) + 8 + 글(500·12.5 h1.65 body)
  Widget _numberedList(BuildContext context, List<String> items) {
    final number = context.typo.caption1W600.copyWith(
      fontSize: 12.5, fontWeight: context.typo.bold, height: 1.65, color: colors.arrow);
    final text = context.typo.caption1W500.copyWith(fontSize: 12.5, height: 1.65, color: colors.body);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (i, item) in items.indexed) ...[
        if (i > 0) const SizedBox(height: 5),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 12, child: Text('${i + 1}.', style: number)),
          const SizedBox(width: 8),
          Expanded(child: Text(item, style: text)),
        ]),
      ],
    ]);
  }

  /// table·kv 공통 카드: surface + 1px border + r16, 둘째 행부터 위에 1px divider
  Widget _card(List<Widget> rows) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) Container(height: 1, color: colors.divider),
            row,
          ],
        ]),
      );

  /// table 행: padding 11/14, 왼쪽(폭 58: 이름 700·12 + 4 + 배지) + 10 + 오른쪽(500·12 h1.55 body)
  Widget _tableRow(BuildContext context, LegalTableRow row) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 58,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(row.name, style: context.typo.caption1W600.copyWith(fontWeight: context.typo.bold, color: colors.text)),
              const SizedBox(height: 4),
              _badge(context, row),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(row.detail, style: context.typo.caption1W500.copyWith(height: 1.55, color: colors.body))),
        ]),
      );

  /// 배지 700·9.5, padding 2/6, r20. 필수: coral + coralTint / 자동: textFaint + segBg
  Widget _badge(BuildContext context, LegalTableRow row) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: row.isRequired ? colors.coralTint : colors.segBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(row.badge, style: context.typo.caption2W600.copyWith(
          fontSize: 9.5, fontWeight: context.typo.bold, color: row.isRequired ? colors.coral : colors.textFaint)),
      );

  /// kv 행: spaceBetween, padding 11/14, 라벨 600·12 textFaint / 값 600·12 arrow
  Widget _keyValueRow(BuildContext context, LegalKeyValue row) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(row.label, style: context.typo.caption1W600.copyWith(color: colors.textFaint)),
          Text(row.value, style: context.typo.caption1W600.copyWith(color: colors.arrow)),
        ]),
      );
}

/// 핸드오프 색 표를 앱 테마에 맞춘 것. 값이 같은 테마 토큰은 그대로 쓰고,
/// 같은 토큰이 없는 자리(body·textFaint·arrow·segBg·segActive·coral)는 밝기별 팔레트 값을 고른다.
class _LegalColors {
  const _LegalColors({
    required this.surface,
    required this.border,
    required this.divider,
    required this.text,
    required this.body,
    required this.textFaint,
    required this.arrow,
    required this.segBg,
    required this.segActive,
    required this.coral,
    required this.coralTint,
  });

  factory _LegalColors.of(BuildContext context) {
    final c = context.color;
    final dark = context.theme.brightness == Brightness.dark;
    return _LegalColors(
      surface: c.background.surface,
      border: c.line.normal,
      divider: c.line.alternative,
      text: c.label.normal,
      body: dark ? Palette.darkTextBody : Palette.labelNeutral,
      textFaint: dark ? Palette.darkTextMuted : Palette.labelAssistive,
      arrow: dark ? Palette.darkTextDisabled : Palette.labelFaint,
      segBg: dark ? Palette.darkSurface : Palette.backgroundAlternative,
      segActive: dark ? Palette.darkBorder : Palette.surface,
      coral: dark ? Palette.coralSoft : Palette.primaryNormal,
      coralTint: c.primary.tint,
    );
  }

  final Color surface;
  final Color border;
  final Color divider;
  final Color text;
  final Color body;
  final Color textFaint;
  final Color arrow;
  final Color segBg;
  final Color segActive;
  final Color coral;
  final Color coralTint;
}
