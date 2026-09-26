import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 계약 suite가 겨냥하는 서버.
///
/// [dio]는 그 서버로 보내는 클라이언트이고, [idToken]은 그 서버가 테스트 로그인으로 받아들이는
/// 소셜 토큰이다. 지금 대상은 Stub 하나다. Gleam 서버를 붙일 때 그 서버의 대상을 하나 더 만든다
/// (테스트 로그인을 어떻게 받아들일지는 그때 정한다).
class ContractTarget {
  ContractTarget({required this.dio, this.idToken = 'contract-test-id-token'});

  final Dio dio;
  final String idToken;
}

/// 계약 suite가 보고 판정하는 응답: 상태코드와 JSON 바디.
class ContractResponse {
  ContractResponse(this.status, this.body);

  final int status;
  final Object? body;

  Map<String, dynamic> get json => body! as Map<String, dynamic>;
  List<dynamic> get list => body! as List<dynamic>;

  /// 오류 바디의 `code`.
  String? get code => body is Map ? (body! as Map)['code'] as String? : null;

  @override
  String toString() => 'ContractResponse($status, $body)';
}

/// 경로·바디를 문자열 그대로 보내는 계약 클라이언트. 오류 응답도 던지지 않고 [ContractResponse]로 돌려준다.
class ContractClient {
  ContractClient(this._target);

  final ContractTarget _target;

  /// 대상 서버가 테스트 로그인으로 받아들이는 소셜 토큰.
  String get idToken => _target.idToken;

  Future<ContractResponse> send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    try {
      final res = await _target.dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );
      return ContractResponse(res.statusCode!, res.data);
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) rethrow;
      return ContractResponse(res.statusCode!, res.data);
    }
  }

  /// [provider]로 로그인하고 액세스 토큰을 돌려준다.
  Future<String> login(String provider) async {
    final res = await send('POST', '/v1/auth/login', body: {'provider': provider, 'idToken': _target.idToken});
    expect(res.status, 200, reason: '$res');
    return res.json['accessToken'] as String;
  }
}
