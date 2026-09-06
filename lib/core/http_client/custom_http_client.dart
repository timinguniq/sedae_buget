import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

part 'custom_dio.dart';
part 'http_exception.dart';

final _logger = CustomLogger.create(tag: (CHttpClient).toString());

class CHttpClient {
  CHttpClient._();

  /// 서버용 Dio
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: EnvironmentConfig.env.endpoint.server,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.add(_CustomInterceptor());
}
