// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static const _prefsKey = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get themeMode => _mode;

  Future<void> loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _mode = ThemeMode.values.firstWhere((m) => m.name == raw, orElse: () => ThemeMode.system);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  ThemeData lightThemeData() => _build(LightTheme());
  ThemeData darkThemeData() => _build(DarkTheme());

  /// Material ThemeData 커스텀
  ThemeData _build(AppTheme theme) {
    return ThemeData(
      // Iterable<Adaptation<Object>>? adaptations,
      // bool? applyElevationOverlayColor,
      // NoDefaultCupertinoThemeData? cupertinoOverrideTheme,
      // Iterable<ThemeExtension<dynamic>>? extensions,
      inputDecorationTheme: inputDecorationTheme(theme),
      // MaterialTapTargetSize? materialTapTargetSize,
      // PageTransitionsTheme? pageTransitionsTheme,
      // TargetPlatform? platform,
      // ScrollbarThemeData? scrollbarTheme,
      // InteractiveInkFeatureFactory? splashFactory,
      useMaterial3: true,
      // VisualDensity? visualDensity,

      /// COLOR
      // [colorScheme] is the preferred way to configure colors. The other color
      // Brightness? brightness,
      // Color? canvasColor,
      // Color? cardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.color.primary.normal,
        brightness: theme.brightness,
      ).copyWith(
        primary: theme.color.primary.normal,
        onPrimary: theme.color.static.white,
      ),
      // Color? colorSchemeSeed,
      // Color? dialogBackgroundColor,
      // Color? disabledColor,
      // Color? dividerColor,
      // Color? focusColor,
      // Color? highlightColor,
      // Color? hintColor,
      // Color? hoverColor,
      // Color? indicatorColor,
      // Color? primaryColor,
      // Color? primaryColorDark,
      // Color? primaryColorLight,
      // MaterialColor? primarySwatch,
      scaffoldBackgroundColor: theme.color.background.normal,
      // Color? secondaryHeaderColor,
      // Color? shadowColor,
      // Color? splashColor,
      // Color? unselectedWidgetColor,

      /// TYPOGRAPHY & ICONOGRAPHY
      // String? fontFamily,
      // List<String>? fontFamilyFallback,
      // String? package,
      iconTheme: iconThemeData(theme),
      // IconThemeData? primaryIconTheme,
      // TextTheme? primaryTextTheme,
      // Typography? typography,

      /// COMPONENT THEMES
      // ActionIconThemeData? actionIconTheme,
      appBarTheme: appBarTheme(theme),
      // BadgeThemeData? badgeTheme,
      // MaterialBannerThemeData? bannerTheme,
      // BottomAppBarTheme? bottomAppBarTheme,
      bottomNavigationBarTheme: bottomNavigationBarTheme(theme),
      bottomSheetTheme: bottomSheetThemeData(theme),
      // ButtonBarThemeData? buttonBarTheme,
      // ButtonThemeData? buttonTheme,
      // CardTheme? cardTheme,
      // cardTheme: cardTheme(),
      // CheckboxThemeData? checkboxTheme,
      // ChipThemeData? chipTheme,
      // DataTableThemeData? dataTableTheme,
      // DatePickerThemeData? datePickerTheme,
      // DialogTheme? dialogTheme,
      // DividerThemeData? dividerTheme,
      dividerTheme: dividerTheme(theme),
      drawerTheme: drawerTheme(theme),
      // DropdownMenuThemeData? dropdownMenuTheme,
      // ElevatedButtonThemeData? elevatedButtonTheme,
      // ExpansionTileThemeData? expansionTileTheme,
      // FilledButtonThemeData? filledButtonTheme,
      floatingActionButtonTheme: floatingActionButtonTheme(theme),
      // iconButtonTheme: iconButtonThemeData(),
      // ListTileThemeData? listTileTheme,
      // MenuBarThemeData? menuBarTheme,
      // MenuButtonThemeData? menuButtonTheme,
      // MenuThemeData? menuTheme,
      // NavigationBarThemeData? navigationBarTheme,
      // NavigationDrawerThemeData? navigationDrawerTheme,
      // NavigationRailThemeData? navigationRailTheme,
      // OutlinedButtonThemeData? outlinedButtonTheme,
      // PopupMenuThemeData? popupMenuTheme,
      progressIndicatorTheme: progressIndicatorThemeData(theme),
      // RadioThemeData? radioTheme,
      // SearchBarThemeData? searchBarTheme,
      // SearchViewThemeData? searchViewTheme,
      // SegmentedButtonThemeData? segmentedButtonTheme,
      sliderTheme: sliderThemeData(theme),
      // SnackBarThemeData? snackBarTheme,
      // SwitchThemeData? switchTheme,
      tabBarTheme: tabBarTheme(theme),
      // TextButtonThemeData? textButtonTheme,
      // TextSelectionThemeData? textSelectionTheme,
      // TimePickerThemeData? timePickerTheme,
      // ToggleButtonsThemeData? toggleButtonsTheme,
      // TooltipThemeData? tooltipTheme,
    );
  }

  InputDecorationTheme inputDecorationTheme(AppTheme theme) {
    return InputDecorationTheme(
      labelStyle: theme.typo.body1W500.copyWith(color: theme.color.primary.strong),
      // floatingLabelStyle:,
      helperStyle: theme.typo.label2W400.copyWith(color: theme.color.label.alternative),
      helperMaxLines: 2,
      hintStyle: theme.typo.body1W500.copyWith(color: theme.color.label.assistive),
      hintFadeDuration: const Duration(milliseconds: 100),
      errorStyle: theme.typo.label2W400.copyWith(color: theme.color.primary.strong),
      errorMaxLines: 2,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      // floatingLabelAlignment = FloatingLabelAlignment.start:,
      // isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
      // isCollapsed = false:,
      // iconColor:,
      // prefixStyle:,
      // prefixIconColor:,
      // suffixStyle:,
      // suffixIconColor:,
      // counterStyle:,
      // filled = false:,
      // fillColor:,
      // activeIndicatorBorder:,
      // outlineBorder:,
      // focusColor:,
      // hoverColor:,
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 3, color: theme.color.primary.strong),
        borderRadius: BorderRadius.circular(10),
      ),
      // focusedBorder:,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 3, color: theme.color.label.strong),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 3, color: theme.color.primary.strong),
        borderRadius: BorderRadius.circular(10),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 1, color: theme.color.label.assistive),
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 1, color: theme.color.label.assistive),
        borderRadius: BorderRadius.circular(10),
      ),
      // border:,
      alignLabelWithHint: true,
      // constraints:,
    );
  }

  AppBarTheme appBarTheme(AppTheme theme) {
    return AppBarTheme(
      backgroundColor: theme.color.background.normal,
      iconTheme: iconThemeData(theme),
      actionsIconTheme: iconThemeData(theme),
      centerTitle: true,
    );
  }

  IconThemeData iconThemeData(AppTheme theme) {
    return IconThemeData(
      size: IconSize.md.getIconSize(),
      color: theme.color.line.strong,
    );
  }

  BottomNavigationBarThemeData bottomNavigationBarTheme(AppTheme theme) {
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

  BottomSheetThemeData bottomSheetThemeData(AppTheme theme) {
    return BottomSheetThemeData(
      modalBackgroundColor: theme.color.background.normal,
      modalBarrierColor: theme.color.material.scrim40,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      showDragHandle: true,
      dragHandleColor: theme.color.static.black,
      dragHandleSize: const Size(48, 4),
      // constraints: const BoxConstraints(maxHeight: 600),
    );
  }

  DividerThemeData dividerTheme(AppTheme theme) {
    return DividerThemeData(
      color: theme.color.line.strong,
      space: 1,
      thickness: 1,
    );
  }

  DrawerThemeData drawerTheme(AppTheme theme) {
    return DrawerThemeData(
      elevation: 0,
      backgroundColor: theme.color.background.normal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }

  FloatingActionButtonThemeData floatingActionButtonTheme(AppTheme theme) {
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

  ProgressIndicatorThemeData progressIndicatorThemeData(AppTheme theme) {
    return ProgressIndicatorThemeData(
      color: theme.color.line.strong,
      linearTrackColor: theme.color.line.normal,
      linearMinHeight: 2,
      refreshBackgroundColor: theme.color.background.alternative,
    );
  }

  SliderThemeData sliderThemeData(AppTheme theme) {
    return SliderThemeData(
      activeTrackColor: theme.color.primary.normal,
      inactiveTrackColor: theme.color.line.normal,
      thumbColor: theme.color.primary.normal,
      overlayColor: theme.color.primary.normal.withValues(alpha: 0.12),
    );
  }

  TabBarThemeData tabBarTheme(AppTheme theme) {
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
}

final _lightTheme = LightTheme();
final _darkTheme = DarkTheme();

extension ThemeServiceExt on BuildContext {
  ThemeService get themeService => watch<ThemeService>();

  AppTheme get theme => Theme.of(this).brightness == Brightness.dark ? _darkTheme : _lightTheme;

  AppColor get color => theme.color;

  AppDeco get deco => theme.deco;

  AppTypo get typo => theme.typo;
}
