import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

class DarkTheme implements AppTheme {
  @override
  Brightness brightness = Brightness.dark;

  @override
  AppColor color = const AppColor(
    primary: PrimaryColorType(
      normal: Palette.primaryNormal, strong: Palette.primaryHeavy,
      heavy: Palette.primaryHeavy, tint: Palette.coralTintDark,
    ),
    label: LabelColorType(
      normal: Palette.darkText, strong: Palette.darkText, neutral: Palette.darkTextSecondary,
      alternative: Palette.darkTextMuted, assistive: Palette.darkTextFaint,
      disable: Palette.darkTextDisabled, white: Palette.labelWhite,
    ),
    background: BackgroundColorType(
      normal: Palette.darkBg, surface: Palette.darkSurface, alternative: Palette.darkSurfaceSunken,
    ),
    line: LineColorType(
      normal: Palette.darkBorder, strong: Palette.darkText, neutral: Palette.darkSurfaceSunken,
      alternative: Palette.darkBorder, white: Palette.lineWhite, orange: Palette.primaryNormal,
    ),
    status: StatusColorType(
      positive: Palette.statusPositive, cautionary: Palette.primaryNormal, destructive: Palette.statusDestructive,
    ),
    accent: AccentColorType(yellow: Palette.accentYellow, blue: Palette.accentBlue, violet: Palette.accentViolet, jade: Palette.accentJade),
    static: StaticColorType(white: Palette.staticWhite, black: Palette.staticBlack),
    fill: FillColorType(
      white: Palette.darkSurface, black: Palette.fillBlack, grey: Palette.darkSurfaceSunken,
      lightGrey: Palette.darkSurfaceSunken, yellow: Palette.fillYellow, lightBlue: Palette.fillLightBlue, lightPink: Palette.coralTintDark,
    ),
    material: MaterialColorType(scrim13: Palette.materialScrim13, scrim40: Palette.materialScrim40, toast: Palette.materialToast),
    undefined: Palette.undefined,
  );

  @override
  late AppTypo typo = AppTypo(
    typo: const Pretendard(),
    fontColor: color.label.strong,
  );

  @override
  AppDeco deco = const AppDeco(
    shadow: [BoxShadow(color: Color(0x59000000), blurRadius: 34, offset: Offset(0, 12))],
    cardShadow: [BoxShadow(color: Color(0x59000000), blurRadius: 34, offset: Offset(0, 12))],
    coralShadow: [BoxShadow(color: Color(0x42F2603C), blurRadius: 26, offset: Offset(0, 12))],
  );
}
