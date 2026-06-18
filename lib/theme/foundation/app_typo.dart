part of 'app_theme.dart';

class AppTypo {
  AppTypo({
    required this.typo,
    required this.fontColor,
  });

  /// Typo
  final Typo typo;

  /// Font Weight
  late FontWeight regular = typo.regular;
  late FontWeight medium = typo.medium;
  late FontWeight semiBold = typo.semiBold;
  late FontWeight bold = typo.bold;

  /// Font Color
  final Color fontColor;

  //------------------------- New -------------------------\\

  late final TextStyle textBasic = TextStyle(
    fontFamily: typo.name,
    color: fontColor,
    fontSize: 100,
    fontWeight: typo.regular,
    decoration: TextDecoration.none,
  );

  late final TextStyle hero1 = textBasic.copyWith(fontSize: 56, height: 1.196, letterSpacing: -0.84); // h66.976
  late final TextStyle hero1W400 = hero1;
  late final TextStyle hero1W600 = hero1.copyWith(fontWeight: typo.semiBold);
  late final TextStyle hero1W700 = hero1.copyWith(fontWeight: typo.bold);

  late final TextStyle display1 = textBasic.copyWith(fontSize: 40, height: 1.2, letterSpacing: -0.48); // h48
  late final TextStyle display1W400 = display1;
  late final TextStyle display1W600 = display1.copyWith(fontWeight: typo.semiBold);
  late final TextStyle display1W700 = display1.copyWith(fontWeight: typo.bold);

  late final TextStyle title1 = textBasic.copyWith(fontSize: 36, height: 1.194, letterSpacing: -0.43); // h42.984
  late final TextStyle title1W400 = title1;
  late final TextStyle title1W600 = title1.copyWith(fontWeight: typo.semiBold);
  late final TextStyle title1W700 = title1.copyWith(fontWeight: typo.bold);

  late final TextStyle title2 = textBasic.copyWith(fontSize: 28, height: 1.357, letterSpacing: -0.17); // h37.996
  late final TextStyle title2W400 = title2;
  late final TextStyle title2W600 = title2.copyWith(fontWeight: typo.semiBold);
  late final TextStyle title2W700 = title2.copyWith(fontWeight: typo.bold);

  late final TextStyle title3 = textBasic.copyWith(fontSize: 24, height: 1.333, letterSpacing: -0.05); // h31.992
  late final TextStyle title3W400 = title3;
  late final TextStyle title3W600 = title3.copyWith(fontWeight: typo.semiBold);
  late final TextStyle title3W700 = title3.copyWith(fontWeight: typo.bold);

  late final TextStyle heading1 = textBasic.copyWith(fontSize: 22, height: 1.318, letterSpacing: -0.04); // h28.996
  late final TextStyle heading1W400 = heading1;
  late final TextStyle heading1W500 = heading1.copyWith(fontWeight: typo.medium);
  late final TextStyle heading1W600 = heading1.copyWith(fontWeight: typo.semiBold);

  late final TextStyle heading2 = textBasic.copyWith(fontSize: 20, height: 1.4); // h28
  late final TextStyle heading2W400 = heading2;
  late final TextStyle heading2W500 = heading2.copyWith(fontWeight: typo.medium);
  late final TextStyle heading2W600 = heading2.copyWith(fontWeight: typo.semiBold);
  late final TextStyle heading2W700 = heading2.copyWith(fontWeight: typo.bold);

  late final TextStyle headline1 = textBasic.copyWith(fontSize: 18, height: 1.444); // h25.992
  late final TextStyle headline1W400 = headline1;
  late final TextStyle headline1W500 = headline1.copyWith(fontWeight: typo.medium);
  late final TextStyle headline1W600 = headline1.copyWith(fontWeight: typo.semiBold);

  late final TextStyle headline2 = textBasic.copyWith(fontSize: 17, height: 1.412); // h24.004
  late final TextStyle headline2W400 = headline2;
  late final TextStyle headline2W500 = headline2.copyWith(fontWeight: typo.medium);
  late final TextStyle headline2W600 = headline2.copyWith(fontWeight: typo.semiBold);

  late final TextStyle body1 = textBasic.copyWith(fontSize: 16, height: 1.5, letterSpacing: 0.09); // h24
  late final TextStyle body1W400 = body1;
  late final TextStyle body1W500 = body1.copyWith(fontWeight: typo.medium);
  late final TextStyle body1W600 = body1.copyWith(fontWeight: typo.semiBold);

  late final TextStyle body2 = textBasic.copyWith(fontSize: 15, height: 1.467, letterSpacing: 0.15); // h22.005
  late final TextStyle body2W400 = body2;
  late final TextStyle body2W500 = body2.copyWith(fontWeight: typo.medium);
  late final TextStyle body2W600 = body2.copyWith(fontWeight: typo.semiBold);

  late final TextStyle label1 = textBasic.copyWith(fontSize: 15, height: 1.2, letterSpacing: 0.151); // h18
  late final TextStyle label1W400 = label1;
  late final TextStyle label1W500 = label1.copyWith(fontWeight: typo.medium);
  late final TextStyle label1W600 = label1.copyWith(fontWeight: typo.semiBold);

  late final TextStyle label2 = textBasic.copyWith(fontSize: 14, height: 1.214, letterSpacing: 0.14); // h16.996
  late final TextStyle label2W400 = label2;
  late final TextStyle label2W500 = label2.copyWith(fontWeight: typo.medium);
  late final TextStyle label2W600 = label2.copyWith(fontWeight: typo.semiBold);

  late final TextStyle caption1 = textBasic.copyWith(fontSize: 12, height: 1.167, letterSpacing: 0.12); // h14.004
  late final TextStyle caption1W400 = caption1;
  late final TextStyle caption1W500 = caption1.copyWith(fontWeight: typo.medium);
  late final TextStyle caption1W600 = caption1.copyWith(fontWeight: typo.semiBold);

  late final TextStyle caption2 = textBasic.copyWith(fontSize: 10, height: 1.2, letterSpacing: 0.1); // h12
  late final TextStyle caption2W400 = caption2;
  late final TextStyle caption2W500 = caption2.copyWith(fontWeight: typo.medium);
  late final TextStyle caption2W600 = caption2.copyWith(fontWeight: typo.semiBold);

  late final TextStyle captionLine = caption2.copyWith(
    decoration: TextDecoration.underline,
    color: Palette.primaryStrong,
  ); // h12
  late final TextStyle captionLineW400 = captionLine;
  late final TextStyle captionLineW500 = captionLine.copyWith(fontWeight: typo.medium);
  late final TextStyle captionLineW600 = captionLine.copyWith(fontWeight: typo.semiBold);

  late final TextStyle _accentTextBasic = TextStyle(
    fontFamily: 'IBMPlexSans',
    color: fontColor,
    fontSize: 100,
    fontWeight: typo.regular,
    decoration: TextDecoration.none,
  );

  late final TextStyle hero = _accentTextBasic.copyWith(fontSize: 50, height: 1.08, letterSpacing: -0.75); // h54
  late final TextStyle heroW400 = hero;
  late final TextStyle heroW600 = hero.copyWith(fontWeight: typo.semiBold);
  late final TextStyle heroW700 = hero.copyWith(fontWeight: typo.bold);

  late final TextStyle display = _accentTextBasic.copyWith(fontSize: 40, height: 1.2, letterSpacing: -0.6); // h48
  late final TextStyle displayW400 = display;
  late final TextStyle displayW600 = display.copyWith(fontWeight: typo.semiBold);
  late final TextStyle displayW700 = display.copyWith(fontWeight: typo.bold);

  late final TextStyle title = _accentTextBasic.copyWith(fontSize: 27, height: 1.222, letterSpacing: -0.41); // h32.994
  late final TextStyle titleW400 = title;
  late final TextStyle titleW600 = title.copyWith(fontWeight: typo.semiBold);
  late final TextStyle titleW700 = title.copyWith(fontWeight: typo.bold);

  late final TextStyle titleItalic = title.copyWith(fontStyle: FontStyle.italic); // h32.994
  late final TextStyle titleItalicW400 = titleItalic;
  late final TextStyle titleItalicW600 = titleItalic.copyWith(fontWeight: typo.semiBold);
  late final TextStyle titleItalicW700 = titleItalic.copyWith(fontWeight: typo.bold);

  late final TextStyle titleReading = _accentTextBasic.copyWith(fontSize: 18, height: 1.333); // h23.994
  late final TextStyle titleReadingW400 = titleReading;
  late final TextStyle titleReadingW600 = titleReading.copyWith(fontWeight: typo.semiBold);
  late final TextStyle titleReadingW700 = titleReading.copyWith(fontWeight: typo.bold);

}
