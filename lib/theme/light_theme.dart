import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

class LightTheme implements AppTheme {
  @override
  Brightness brightness = Brightness.light;

  @override
  AppColor color = const AppColor(
    primary: PrimaryColorType(
      normal: Palette.primaryNormal,
      strong: Palette.primaryStrong,
      heavy: Palette.primaryHeavy,
      tint: Palette.coralTint,
    ),
    label: LabelColorType(
      normal: Palette.labelNormal,
      strong: Palette.labelStrong,
      neutral: Palette.labelNeutral,
      alternative: Palette.labelAlternative,
      assistive: Palette.labelAssistive,
      disable: Palette.labelDisable,
      white: Palette.fillWhite,
    ),
    background: BackgroundColorType(
      normal: Palette.backgroundNormal,
      surface: Palette.surface,
      alternative: Palette.backgroundAlternative,
    ),
    line: LineColorType(
      normal: Palette.lineNormal,
      strong: Palette.lineStrong,
      neutral: Palette.lineNeutral,
      alternative: Palette.lineAlternative,
      white: Palette.lineWhite,
      orange: Palette.lineOrange,
    ),
    status: StatusColorType(
      positive: Palette.statusPositive,
      cautionary: Palette.statusCautionary,
      destructive: Palette.statusDestructive,
    ),
    accent: AccentColorType(
      yellow: Palette.accentYellow,
      blue: Palette.accentBlue,
      violet: Palette.accentViolet,
      jade: Palette.accentJade,
    ),
    static: StaticColorType(
      white: Palette.staticWhite,
      black: Palette.staticBlack,
    ),
    fill: FillColorType(
      white: Palette.fillWhite,
      black: Palette.fillBlack,
      grey: Palette.fillGrey,
      lightGrey: Palette.fillLightGrey,
      yellow: Palette.fillYellow,
      lightBlue: Palette.fillLightBlue,
      lightPink: Palette.fillLightPink,
    ),
    material: MaterialColorType(
      scrim13: Palette.materialScrim13,
      scrim40: Palette.materialScrim40,
      toast: Palette.materialToast,
    ),
    undefined: Palette.undefined,
  );

  @override
  late AppTypo typo = AppTypo(
    typo: const Pretendard(),
    fontColor: color.label.strong,
  );

  @override
  AppDeco deco = const AppDeco(
    shadow: [BoxShadow(color: Color(0x122B2724), blurRadius: 34, offset: Offset(0, 12))],
    cardShadow: [BoxShadow(color: Color(0x122B2724), blurRadius: 34, offset: Offset(0, 12))],
    coralShadow: [BoxShadow(color: Color(0x42F2603C), blurRadius: 26, offset: Offset(0, 12))],
  );
}
