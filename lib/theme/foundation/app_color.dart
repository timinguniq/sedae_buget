part of 'app_theme.dart';

class AppColor {
  const AppColor({
    required this.primary,
    required this.label,
    required this.background,
    required this.line,
    required this.status,
    required this.accent,
    required this.static,
    required this.fill,
    required this.material,
    required this.undefined,
  });

  final PrimaryColorType primary;
  final LabelColorType label;
  final BackgroundColorType background;
  final LineColorType line;
  final StatusColorType status;
  final AccentColorType accent;
  final StaticColorType static;
  final FillColorType fill;
  final MaterialColorType material;
  final Color undefined;
}

class PrimaryColorType {
  const PrimaryColorType({
    required this.normal,
    required this.strong,
    required this.heavy,
  });

  final Color normal;
  final Color strong;
  final Color heavy;
}

class LabelColorType {
  const LabelColorType({
    required this.normal,
    required this.strong,
    required this.neutral,
    required this.alternative,
    required this.assistive,
    required this.disable,
    required this.white,
  });

  final Color normal;
  final Color strong;
  final Color neutral;
  final Color alternative;
  final Color assistive;
  final Color disable;
  final Color white;
}

class BackgroundColorType {
  const BackgroundColorType({
    required this.normal,
    required this.alternative,
  });

  final Color normal;
  final Color alternative;
}

class LineColorType {
  const LineColorType({
    required this.normal,
    required this.strong,
    required this.neutral,
    required this.alternative,
    required this.white,
    required this.orange,
  });

  final Color normal;
  final Color strong;
  final Color neutral;
  final Color alternative;
  final Color white;
  final Color orange;
}

class StatusColorType {
  const StatusColorType({
    required this.positive,
    required this.cautionary,
    required this.destructive,
  });

  final Color positive;
  final Color cautionary;
  final Color destructive;
}

class AccentColorType {
  const AccentColorType({
    required this.yellow,
    required this.blue,
    required this.violet,
    required this.jade,
  });

  final Color yellow;
  final Color blue;
  final Color violet;
  final Color jade;
}

class StaticColorType {
  const StaticColorType({
    required this.white,
    required this.black,
  });

  final Color white;
  final Color black;
}

class FillColorType {
  const FillColorType({
    required this.white,
    required this.black,
    required this.grey,
    required this.lightGrey,
    required this.yellow,
    required this.lightBlue,
    required this.lightPink,
  });

  final Color white;
  final Color black;
  final Color grey;
  final Color lightGrey;
  final Color yellow;
  final Color lightBlue;
  final Color lightPink;
}

class MaterialColorType {
  const MaterialColorType({
    required this.scrim13,
    required this.scrim40,
    required this.toast,
  });

  final Color scrim13;
  final Color scrim40;
  final Color toast;
}
