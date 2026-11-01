import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 앱 토큰([AppTheme])으로 만든 Material 테마. 라이트·다크 모두 이 규칙 하나로 만든다.
ThemeData materialTheme(AppTheme theme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: theme.color.primary.normal,
          brightness: theme.brightness,
        ).copyWith(
          primary: theme.color.primary.normal,
          onPrimary: theme.color.static.white,
        ),
    scaffoldBackgroundColor: theme.color.background.normal,
    iconTheme: _iconThemeData(theme),
    inputDecorationTheme: _inputDecorationTheme(theme),
    appBarTheme: _appBarTheme(theme),
    bottomNavigationBarTheme: _bottomNavigationBarTheme(theme),
    bottomSheetTheme: _bottomSheetThemeData(theme),
    dividerTheme: _dividerTheme(theme),
    drawerTheme: _drawerTheme(theme),
    filledButtonTheme: _filledButtonTheme(theme),
    floatingActionButtonTheme: _floatingActionButtonTheme(theme),
    progressIndicatorTheme: _progressIndicatorThemeData(theme),
    sliderTheme: _sliderThemeData(theme),
    switchTheme: _switchThemeData(theme),
    tabBarTheme: _tabBarTheme(theme),
  );
}

InputDecorationTheme _inputDecorationTheme(AppTheme theme) {
  return InputDecorationTheme(
    labelStyle: theme.typo.body1W500.copyWith(
      color: theme.color.primary.strong,
    ),
    helperStyle: theme.typo.label2W400.copyWith(
      color: theme.color.label.alternative,
    ),
    helperMaxLines: 2,
    hintStyle: theme.typo.body1W500.copyWith(
      color: theme.color.label.assistive,
    ),
    hintFadeDuration: const Duration(milliseconds: 100),
    errorStyle: theme.typo.label2W400.copyWith(
      color: theme.color.primary.strong,
    ),
    errorMaxLines: 2,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 3, color: theme.color.primary.strong),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 3, color: theme.color.label.strong),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 3, color: theme.color.primary.strong),
      borderRadius: BorderRadius.circular(10),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.color.label.assistive),
      borderRadius: BorderRadius.circular(10),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.color.label.assistive),
      borderRadius: BorderRadius.circular(10),
    ),
    alignLabelWithHint: true,
  );
}

AppBarTheme _appBarTheme(AppTheme theme) {
  return AppBarTheme(
    backgroundColor: theme.color.background.normal,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    iconTheme: _iconThemeData(theme),
    actionsIconTheme: _iconThemeData(theme),
    centerTitle: true,
  );
}

/// 디자인 기본 버튼: h54 / r16 / 코랄 + 코랄 그림자 / 700·16
FilledButtonThemeData _filledButtonTheme(AppTheme theme) {
  return FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: theme.color.primary.normal,
      foregroundColor: theme.color.static.white,
      disabledBackgroundColor: theme.color.fill.grey,
      disabledForegroundColor: theme.color.label.assistive,
      minimumSize: const Size(64, 54),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: theme.typo.body1W600.copyWith(fontWeight: theme.typo.bold),
      elevation: 6,
      shadowColor: theme.deco.coralShadow.first.color,
    ),
  );
}

IconThemeData _iconThemeData(AppTheme theme) {
  return IconThemeData(
    size: IconSize.md.getIconSize(),
    color: theme.color.line.strong,
  );
}

BottomNavigationBarThemeData _bottomNavigationBarTheme(AppTheme theme) {
  return BottomNavigationBarThemeData(
    backgroundColor: theme.color.background.normal,
    selectedLabelStyle: theme.typo.caption2W500,
    unselectedLabelStyle: theme.typo.caption2W500,
    selectedItemColor: theme.color.primary.strong,
    unselectedItemColor: theme.color.line.strong,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  );
}

BottomSheetThemeData _bottomSheetThemeData(AppTheme theme) {
  return BottomSheetThemeData(
    modalBackgroundColor: theme.color.background.normal,
    modalBarrierColor: theme.color.material.scrim40,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    showDragHandle: true,
    dragHandleColor: theme.color.static.black,
    dragHandleSize: const Size(48, 4),
  );
}

DividerThemeData _dividerTheme(AppTheme theme) {
  return DividerThemeData(
    color: theme.color.line.strong,
    space: 1,
    thickness: 1,
  );
}

DrawerThemeData _drawerTheme(AppTheme theme) {
  return DrawerThemeData(
    elevation: 0,
    backgroundColor: theme.color.background.normal,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  );
}

FloatingActionButtonThemeData _floatingActionButtonTheme(AppTheme theme) {
  return FloatingActionButtonThemeData(
    foregroundColor: theme.color.background.normal,
    backgroundColor: theme.color.primary.normal,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    disabledElevation: 0,
    highlightElevation: 0,
    shape: const CircleBorder(),
    iconSize: IconSize.md.getIconSize(),
    sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
  );
}

ProgressIndicatorThemeData _progressIndicatorThemeData(AppTheme theme) {
  return ProgressIndicatorThemeData(
    color: theme.color.line.strong,
    linearTrackColor: theme.color.line.normal,
    linearMinHeight: 2,
    refreshBackgroundColor: theme.color.background.alternative,
  );
}

/// 디자인 슬라이더: 트랙 8px / 썸 28px(흰색 + 코랄 3.5px 테두리)
SliderThemeData _sliderThemeData(AppTheme theme) {
  return SliderThemeData(
    trackHeight: 8,
    activeTrackColor: theme.color.primary.normal,
    inactiveTrackColor: theme.color.line.normal,
    thumbColor: theme.color.primary.normal,
    thumbShape: _RingThumbShape(fill: theme.color.static.white),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
    overlayColor: theme.color.primary.normal.withValues(alpha: 0.12),
    activeTickMarkColor: Colors.transparent,
    inactiveTickMarkColor: Colors.transparent,
  );
}

/// 디자인 토글: 42×24, 켜짐 코랄 트랙 + 흰 썸
SwitchThemeData _switchThemeData(AppTheme theme) {
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? theme.color.static.white
          : theme.color.label.assistive,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? theme.color.primary.normal
          : theme.color.line.normal,
    ),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    trackOutlineWidth: const WidgetStatePropertyAll(0),
  );
}

TabBarThemeData _tabBarTheme(AppTheme theme) {
  return TabBarTheme(
    indicatorColor: theme.color.primary.strong,
    indicatorSize: TabBarIndicatorSize.tab,
    dividerColor: Colors.transparent,
    labelColor: theme.color.primary.strong,
    labelStyle: theme.typo.label2W600,
    unselectedLabelColor: theme.color.label.strong,
    unselectedLabelStyle: theme.typo.label2W500,
  ).data;
}

/// 흰 원 + 코랄 테두리 썸 (테두리 색은 [SliderThemeData.thumbColor]).
class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape({required this.fill});

  final Color fill;
  static const double radius = 14;
  static const double border = 3.5;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius - border / 2,
      Paint()
        ..color = sliderTheme.thumbColor ?? Palette.primaryNormal
        ..style = PaintingStyle.stroke
        ..strokeWidth = border,
    );
  }
}
