import 'package:flutter/material.dart';

abstract class Palette {
  static const Color undefined = Color(0xFFFF00FF); // 0xFFECEFF2
  static const Color onUndefined = Color(0xFF00FFFF); // 0xFFECEFF2

  /// primary (coral) ----------\\
  static const Color primaryNormal = Color(0xFFF2603C);
  static const Color primaryStrong = Color(0xFFD94E2C);
  static const Color primaryHeavy = Color(0xFFFF6E47);
  static const Color coralSoft = Color(0xFFFF8A6B); // 다크 배지 텍스트
  static const Color coralTint = Color(0xFFFEF0EB);

  /// label (warm ink/gray) ----------\\
  static const Color labelNormal = Color(0xFF2B2724);
  static const Color labelStrong = Color(0xFF2B2724);
  static const Color labelNeutral = Color(0xFF6F6862);
  static const Color labelAlternative = Color(0xFF8C857D);
  static const Color labelAssistive = Color(0xFFA8A099);
  static const Color labelDisable = Color(0xFFB8B0A8);
  static const Color labelWhite = Color(0xFFFFFFFF);

  /// background ----------\\
  static const Color backgroundNormal = Color(0xFFFBFAF7); // bg
  static const Color surface = Color(0xFFFFFFFF); // 카드
  static const Color backgroundAlternative = Color(0xFFF1ECE4); // surfaceSunken
  static const Color cream = Color(0xFFFBF6EF);

  /// line / border ----------\\
  static const Color lineNormal = Color(0xFFEDE9E3); // border
  static const Color lineStrong = Color(0xFF2B2724);
  static const Color lineNeutral = Color(0xFFDCD5CC); // neutral-300
  static const Color neutral400 = Color(0xFFC9C1B8);
  static const Color lineAlternative = Color(0xFFF1ECE4);
  static const Color lineWhite = Color(0xFFFFFFFF);
  static const Color lineOrange = Color(0xFFF2603C);

  /// status -------------------------\\
  static const Color statusPositive = Color(0xFF00BF40);
  static const Color statusCautionary = Color(0xFFD94E2C);
  static const Color statusDestructive = Color(0xFFFF4242);

  /// accent -------------------------\\
  static const Color accentYellow = Color(0xFFFFE400);
  static const Color accentBlue = Color(0xFF3374E8);
  static const Color accentViolet = Color(0xFF9343F4);
  static const Color accentJade = Color(0xFF2DC9C9);

  /// static -------------------------\\
  static const Color staticWhite = Color(0xFFFFFFFF);
  static const Color staticBlack = Color(0xFF000000);

  /// fill -------------------------\\
  static const Color fillWhite = Color(0xFFFFFFFF);
  static const Color fillBlack = Color(0xFF000000);
  static const Color fillGrey = Color(0xFFE6E1D8);
  static const Color fillLightGrey = Color(0xFFF1ECE4);
  static const Color fillYellow = Color(0xFFFFF06F);
  static const Color fillLightBlue = Color(0xFFC1E1FF);
  static const Color fillLightPink = Color(0xFFFFD7FB);

  /// material -------------------------\\
  static const Color materialScrim13 = Color(0x21000000);
  static const Color materialScrim40 = Color(0x66000000);
  static const Color materialToast = Color(0xF95D5E62);

  /// neutral ramp (차트/도넛/바) — 디자인 램프 300·400·500·600·700·200 순 ----------\\
  static const List<Color> neutralRamp = [
    Color(0xFFDCD5CC), Color(0xFFC9C1B8), Color(0xFFB8B0A8),
    Color(0xFFA29A92), Color(0xFF8C857D), Color(0xFFE6E1D8),
  ];

  /// dark chart ramp (다크 도넛/바) ----------\\
  static const List<Color> darkRamp = [
    Color(0xFF3A332C), Color(0xFF4A433C), Color(0xFF5A534C),
  ];

  /// dark ----------\\
  static const Color darkBg = Color(0xFF1A1714);
  static const Color darkSurface = Color(0xFF241F1B);
  static const Color darkSurfaceSunken = Color(0xFF2E2823);
  static const Color darkBorder = Color(0xFF332C26);
  static const Color darkText = Color(0xFFF5F1EC);
  static const Color darkTextSecondary = Color(0xFFA9A199);
  static const Color darkTextMuted = Color(0xFF8C857D);
  static const Color darkTextFaint = Color(0xFF6E665E);
  static const Color darkTextDisabled = Color(0xFF5A534C);
  static const Color coralTintDark = Color(0xFF3A241C);

//------------------------- gradient -------------------------\\
// static const Gradient yellowCoralGradient = LinearGradient(
//   colors: <Color>[yellow400, coral400],
//   begin: Alignment.topCenter,
//   end: Alignment.bottomCenter,
// );
}
