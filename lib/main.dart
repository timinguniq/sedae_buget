import 'dart:async';

import 'package:sedae_budget/presentation/presentation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_config/remote_config.dart';
import 'core/util/logger/custom_logger.dart';
import 'package:provider/provider.dart' as provider;

final _logger = CustomLogger.create(tag: 'main');

Future<void> main() async {
  unawaited(
    runZonedGuarded(() async {
      //---------------- Configuration initialize -------------------\\
      WidgetsFlutterBinding.ensureInitialized();

      await initializeDateFormatting();
      await dotenv.load();

      //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

      await RemoteConfig.initialize();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      //HttpOverrides.global = NoCheckCertificateHttpOverrides(); // 생성된 HttpOverrides 객체 등록

      runApp(
        ProviderScope(
          child: provider.ChangeNotifierProvider(
            create: (context) => ThemeService(),
            child: const MyApp(),
          ),
        ),
      );
    }, (e, s) {
      // 글로벌 에러 핸들링
      _logger.e('Unhandled Exception:', error: e, stackTrace: s);
      FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      ),
      routerConfig: router,
      title: 'Base flutter app',
      debugShowCheckedModeBanner: false,
      theme: context.themeService.themeData(),
    );
  }
}
