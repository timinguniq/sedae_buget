import 'package:dio/dio.dart';
import 'package:sedae_budget/data/data.dart';

import 'api_contract.dart';
import 'contract_target.dart';

/// 앱이 local 환경에서 서버 대신 쓰는 Stub이 계약을 지키는가.
void main() => apiContract(() {
      final dio = Dio(BaseOptions(contentType: 'application/json'))..interceptors.add(StubApiInterceptor());
      return ContractTarget(dio: dio);
    });
