import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';
import 'package:sedae_budget/entity/entity.dart';

final _logger = CustomLogger.create(tag: 'session');

/// 로그인 세션: 서버가 준 액세스 토큰을 기기에 두고, 요청마다 붙이고, 끝낸다.
///
/// - 토큰은 [AuthTokenStore] adapter에 둔다(앱: 보안 저장소, 테스트: 메모리).
/// - [interceptor]가 모든 요청에 `Authorization: Bearer`를 붙인다(이미 적힌 요청 — 로그아웃 — 은 그대로 둔다). 서버가 지금 가진 토큰을 거부하면(401)
///   토큰을 지우고 [expired]로 알린다. 앱을 켤 때 세션을 확인하다가도, 쓰는 중에도 같다.
/// - 저장소를 읽지 못하면(키 저장소 고장) 세션이 없는 것으로 본다. 다시 시도해도 고쳐지지 않으므로 토큰 지우기를
///   시도하고, 요청을 보내던 중이었으면 [expired]로 알린다(다시 로그인하게). 요청은 토큰 없이 보낸다.
/// - [start]·[end]는 저장소에 쓰고 지우는 일이다. 실패해도 던지지 않고 [Result.failure](unknown)로 돌려준다.
/// - [end]는 기기의 토큰을 먼저 지우고, 지웠을 때만 서버에 알린다. 못 지우면 서버 세션도 그대로라 계속 쓸 수 있다.
class Session {
  Session(this._store);

  final AuthTokenStore _store;
  final _expired = StreamController<void>.broadcast();

  /// 세션이 끝났다: 서버가 토큰을 거부했거나 쓰는 중에 저장소를 읽지 못했다. 알릴 때는 토큰 지우기를 이미 시도했다.
  Stream<void> get expired => _expired.stream;

  /// 요청에 토큰을 붙이고 401을 보는 Dio 인터셉터. 서버 응답보다 앞에 둔다(`connectToServer`).
  late final Interceptor interceptor = _SessionInterceptor(this);

  /// 저장된 세션이 있는가. 저장소를 읽지 못하면 없는 것으로 본다.
  Future<bool> get isActive async => (await _read()).token != null;

  /// 서버가 준 [token]으로 세션을 시작한다.
  Future<Result<void>> start(String token) => _guard(() => _store.write(token));

  /// 이 기기의 세션을 끝낸다. 토큰을 지운 다음 [tellServer]에 그 토큰의 `Authorization` 값을 넘겨 서버에 알린다.
  /// 토큰을 지우지 못하면 서버에 알리지 않고 실패다(세션은 그대로 쓸 수 있다). 서버에 알리지 못해도 성공이다.
  Future<Result<void>> end({Future<void> Function(String authorization)? tellServer}) async {
    final saved = await _read();
    final cleared = await _guard(_store.clear);
    final token = saved.token;
    if (cleared.failureOrNull == null && token != null) await tellServer?.call('$_scheme$token');
    return cleared;
  }

  static const _header = 'Authorization';
  static const _scheme = 'Bearer ';

  /// 저장된 토큰. 읽지 못했으면 세션을 버리고(지우기 시도) [unreadable]이 true다.
  Future<({String? token, bool unreadable})> _read() async {
    try {
      final token = await _store.read();
      return (token: token == null || token.isEmpty ? null : token, unreadable: false);
    } catch (e, s) {
      _logger.e('토큰 저장소를 읽지 못해 세션을 끝내요', error: e, stackTrace: s);
      await _guard(_store.clear);
      return (token: null, unreadable: true);
    }
  }

  /// 서버가 거부한 [rejected] 토큰이 지금 가진 토큰이면 세션을 끝낸다.
  /// 그 사이 새로 로그인했다면 새 토큰은 그대로 둔다.
  Future<void> _rejected(String rejected) async {
    final current = await _read();
    if (current.unreadable) return _expired.add(null);
    if (current.token != rejected) return;
    await _guard(_store.clear);
    _expired.add(null);
  }

  Future<Result<void>> _guard(Future<void> Function() run) async {
    try {
      await run();
      return const Result.success(null);
    } catch (e, s) {
      _logger.e('토큰 저장소에 접근하지 못했어요', error: e, stackTrace: s);
      return const Result.failure(ErrorResult(reason: FailureReason.unknown, message: ''));
    }
  }
}

class _SessionInterceptor extends Interceptor {
  _SessionInterceptor(this._session);

  final Session _session;

  static const _header = Session._header;
  static const _scheme = Session._scheme;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 끝낼 세션을 직접 적은 요청(로그아웃)은 그대로 보낸다. 그 사이 새로 로그인했어도 새 토큰으로 덮지 않는다.
    if (options.headers.containsKey(_header)) return handler.next(options);
    final saved = await _session._read();
    if (saved.unreadable) _session._expired.add(null);
    final token = saved.token;
    if (token != null) options.headers[_header] = '$_scheme$token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final sent = err.requestOptions.headers[_header];
    if (err.response?.statusCode == 401 && sent is String && sent.startsWith(_scheme)) {
      await _session._rejected(sent.substring(_scheme.length));
    }
    handler.next(err);
  }
}
