import 'dart:async';

import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/local_storage/local_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      configureApiDependencies(SecureAuthTokenStore(await LocalStorage.getInstance()));
      configureBudgetDependencies();
      configurePeerDependencies();
      configureUserDependencies();
      configureAdDependencies(await SharedPreferences.getInstance());
      configureAppStatusDependencies();
      unawaited(locator<AdService>().initialize()); // 부팅을 막지 않고 미리 워밍업

      //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      try {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
      } catch (e, s) {
        _logger.w('Firebase unavailable (local boot): $e', stackTrace: s);
      }

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      //HttpOverrides.global = NoCheckCertificateHttpOverrides(); // 생성된 HttpOverrides 객체 등록

      runApp(
        ProviderScope(
          child: provider.ChangeNotifierProvider(
            create: (context) => ThemeService()..loadPersisted(),
            child: const MyApp(),
          ),
        ),
      );
    }, (e, s) {
      // 글로벌 에러 핸들링
      _logger.e('Unhandled Exception:', error: e, stackTrace: s);
      try {
        FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
      } catch (_) {
        // Crashlytics unavailable (local boot); ignore.
      }
    }),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 쓰는 중에 점검·업데이트가 걸리면 지금 화면 위에 안내한다(앱을 켤 때는 스플래시가 안내한다).
    ref.listen(appStatusUpdatesProvider, (_, next) {
      final navigator = rootNavigatorKey.currentContext;
      final status = next.value;
      if (navigator != null && status != null) {
        unawaited(showAppStatusDialog(navigator, status, exitApp: ref.read(appExitProvider)));
      }
    });
    return MaterialApp.router(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      ),
      routerConfig: ref.watch(routerProvider),
      title: '세대 가계부',
      debugShowCheckedModeBanner: false,
      theme: context.themeService.lightThemeData(),
      darkTheme: context.themeService.darkThemeData(),
      themeMode: context.themeService.themeMode,
    );
  }
}
