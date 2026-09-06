import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 테마 선택 카드: "테마" + 현재값 행 → 미니 프리뷰 썸네일 3개(라이트/다크/시스템, h62·r13).
/// 선택 시 2px 코랄 테두리 + 라벨 700 잉크.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const _labels = {ThemeMode.light: '라이트', ThemeMode.dark: '다크', ThemeMode.system: '시스템'};

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('테마', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
          Text(_labels[value]!,
            style: context.typo.caption1W600.copyWith(fontSize: 11.5, color: context.color.label.assistive)),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          _thumb(context, ThemeMode.light),
          const SizedBox(width: 8),
          _thumb(context, ThemeMode.dark),
          const SizedBox(width: 8),
          _thumb(context, ThemeMode.system),
        ]),
      ]),
    );
  }

  Widget _thumb(BuildContext context, ThemeMode mode) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Container(
            height: 62,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? context.color.primary.normal : context.color.line.normal,
                width: selected ? 2 : 1.5),
            ),
            child: _preview(mode),
          ),
          const SizedBox(height: 7),
          Text(_labels[mode]!,
            style: context.typo.caption2W600.copyWith(
              fontSize: 11,
              fontWeight: selected ? context.typo.bold : context.typo.semiBold,
              color: selected ? context.color.label.normal : context.color.label.alternative)),
        ]),
      ),
    );
  }

  Widget _preview(ThemeMode mode) => switch (mode) {
        ThemeMode.light => const _MiniScreen(bg: Palette.backgroundNormal, bar: Palette.fillGrey),
        ThemeMode.dark => const _MiniScreen(bg: Palette.darkBg, bar: Color(0xFF4A433C)),
        ThemeMode.system => const Row(children: [
            Expanded(child: ColoredBox(color: Palette.backgroundNormal)),
            Expanded(child: ColoredBox(color: Palette.darkBg)),
          ]),
      };
}

/// 코랄 바 55% + 회색 바 2줄의 화면 축소판.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.bg, required this.bar});
  final Color bg;
  final Color bar;

  @override
  Widget build(BuildContext context) {
    Widget line(double h, double w, Color c) => FractionallySizedBox(
      alignment: Alignment.centerLeft, widthFactor: w,
      child: Container(height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))));
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line(7, 0.55, Palette.primaryNormal),
          const SizedBox(height: 4),
          line(5, 1, bar),
          const SizedBox(height: 4),
          line(5, 0.75, bar),
        ]),
      ),
    );
  }
}
