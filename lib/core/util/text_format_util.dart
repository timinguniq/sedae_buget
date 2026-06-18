import 'package:intl/intl.dart';

// DATE_FORMAT --------------------//
const String DEFAULT_DATE_FORMAT = DATE_FORMAT_DASH;
const String DATE_FORMAT_DASH = 'yyyy-MM-dd';
const String DATE_FORMAT_SLASH = 'MM/dd/yyyy';
const String DATE_FORMAT_MONTH_DAY_WEEKDAY = 'MM/dd (EEE)';
const String DATE_FORMAT_DAY_MONTH_YEAR = 'd MMM, yyyy';
const String TIME_FORMAT_12H = 'hh:mm a';

extension IntFormatExtension on int {
  String formatComma({String? suffix, String locale = 'en-US'}) {
    final formattedString = NumberFormat.decimalPattern(locale).format(this);
    return suffix == null ? formattedString : '$formattedString$suffix';
  }

  String formatLoovyLabel({String locale = 'en-US', bool includeSpace = false}) {
    return formatComma(suffix: '${includeSpace ? ' ' : ''}Loovy', locale: locale);
  }

  String formatKookyLabel({String locale = 'en-US', bool includeSpace = false}) {
    return formatComma(suffix: '${includeSpace ? ' ' : ''}Kooky', locale: locale);
  }
}

extension DoubleFormatExtension on double {
  String formatComma({String? suffix, String locale = 'en-US', int? fractionDigits}) {
    if (fractionDigits == 0) {
      return toInt().formatComma(locale: locale);
    }

    final formattedString = fractionDigits == null
        ? NumberFormat.decimalPattern(locale).format(this)
        : NumberFormat.decimalPattern(locale).format(double.parse(toStringAsFixed(fractionDigits)));
    return suffix == null ? formattedString : '$formattedString$suffix';
  }
}

extension DateTimeFormatExtension on DateTime {
  String format([String? pattern = DEFAULT_DATE_FORMAT, String? locale = 'en-US']) {
    return DateFormat(pattern, locale).format(this);
  }
}
