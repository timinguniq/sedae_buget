import 'package:flutter/material.dart';

abstract class Palette {
  static const Color undefined = Color(0xFFFF00FF); // 0xFFECEFF2
  static const Color onUndefined = Color(0xFF00FFFF); // 0xFFECEFF2

  /// primary -------------------------\\
  static const Color primaryNormal = Color(0xFFFF8200);
  static const Color primaryStrong = Color(0xFFFF6A13);
  static const Color primaryHeavy = Color(0xFFE95B04);

  /// label -------------------------\\
  static const Color labelNormal = Color(0xFF171719);
  static const Color labelStrong = Color(0xFF000000);
  static const Color labelNeutral = Color(0xFF656565);
  static const Color labelAlternative = Color(0xFF848484);
  static const Color labelAssistive = Color(0xFF9E9E9E);
  static const Color labelDisable = Color(0xFFEBEBEB);
  static const Color labelWhite = Color(0xFFFFFFFF);

  /// background -------------------------\\
  static const Color backgroundNormal = Color(0xFFFFFFFF);
  static const Color backgroundAlternative = Color(0xFFF7F7F8);

  /// line -------------------------\\
  static const Color lineNormal = Color(0x21000000); //13%
  static const Color lineStrong = Color(0xFF000000);
  static const Color lineNeutral = Color(0x2970737C); //16%
  static const Color lineAlternative = Color(0x1470737C); //8%
  static const Color lineWhite = Color(0xFFFFFFFF);
  static const Color lineOrange = Color(0xFFFF6A13);

  /// status -------------------------\\
  static const Color statusPositive = Color(0xFF00BF40);
  static const Color statusCautionary = Color(0xFFE95B04);
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
  static const Color fillGrey = Color(0xFFEBEBEB);
  static const Color fillLightGrey = Color(0xFFF4F4F4);
  static const Color fillYellow = Color(0xFFFFF06F);
  static const Color fillLightBlue = Color(0xFFC1E1FF);
  static const Color fillLightPink = Color(0xFFFFD7FB);

  /// material -------------------------\\
  static const Color materialScrim13 = Color(0x21000000);
  static const Color materialScrim40 = Color(0x66000000);
  static const Color materialToast = Color(0xF95D5E62);

//------------------------- gradient -------------------------\\
// static const Gradient yellowCoralGradient = LinearGradient(
//   colors: <Color>[yellow400, coral400],
//   begin: Alignment.topCenter,
//   end: Alignment.bottomCenter,
// );
}
