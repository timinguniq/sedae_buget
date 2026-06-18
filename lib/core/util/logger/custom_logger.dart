import 'package:sedae_budget/core/core.dart';
import 'package:logger/logger.dart';

class CustomLogger extends Logger {
  static Logger create({String? tag, bool excludeTimeSinceStart = true}) {
    return Logger(
      printer: PrefixPrinter(
        _CustomPrettyPrinter(tag: tag, excludeTimeSinceStart: excludeTimeSinceStart),
      ),
    );
  }
}

class _CustomPrettyPrinter extends PrettyPrinter {
  _CustomPrettyPrinter({
    this.tag,
    this.excludeTimeSinceStart = true,
  }) : super(
    methodCount: 0,
    errorMethodCount: null,
    lineLength: 120,
    colors: false,
    excludeBox: {
      Level.all: true,
      Level.trace: false,
      Level.debug: true,
      Level.info: true,
      Level.warning: true,
      Level.error: false,
      Level.fatal: false,
      Level.off: false,
    },
    dateTimeFormat: DateTimeFormat.none,
  );

  final String? tag;
  final bool excludeTimeSinceStart;

  @override
  List<String> log(LogEvent event) {
    final time = event.time.format('HH:mm:ss.SSS');
    final prefix = (tag == null) ? time : '$time | $tag';
    return super.log(event.copyWith(message: '$prefix | ${event.message}'));
  }
}

extension LogEventExtension on LogEvent {
  LogEvent copyWith({
    Level? level,
    // ignore: avoid_annotating_with_dynamic
    dynamic message,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return LogEvent(
      level ?? this.level,
      message ?? this.message,
      time: time ?? this.time,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
