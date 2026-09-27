import 'package:flutter/widgets.dart';

/// 광고 SDK 경계. 페이지/위젯은 이 인터페이스만 본다.
/// 실패는 예외 대신 null/false로 알린다 — 광고가 안 떠도 앱은 그대로 돌아가야 한다.
abstract interface class AdService {
  /// SDK 초기화. 여러 번 불러도 한 번만 초기화한다.
  Future<void> initialize();

  /// 배너(320×100) 로드. 실패하면 null. 돌려받은 배너는 쓰는 쪽이 [LoadedBanner.dispose] 한다.
  Future<LoadedBanner?> loadBanner();

  /// 전면 광고 로드. 로드됐으면 true. 이후 [showInterstitial]로 띄운다.
  Future<bool> loadInterstitial();

  /// 로드해 둔 전면 광고를 띄운다. 없으면 아무것도 안 한다.
  Future<void> showInterstitial();
}

/// 광고를 지원하지 않는 플랫폼(web)·테스트용 Null Object.
class NoAdService implements AdService {
  const NoAdService();

  @override
  Future<void> initialize() async {}

  @override
  Future<LoadedBanner?> loadBanner() async => null;

  @override
  Future<bool> loadInterstitial() async => false;

  @override
  Future<void> showInterstitial() async {}
}

/// 로드된 배너. SDK 타입 대신 크기·그릴 위젯·해제만 내보낸다. 쓰는 쪽이 [dispose] 한다.
final class LoadedBanner {
  const LoadedBanner({
    required this.width,
    required this.height,
    required this.view,
    required Future<void> Function() dispose,
  }) : _dispose = dispose;

  /// 배너 크기(논리 픽셀). 캡션이 `320×100`으로 보이게 정수로 둔다.
  final int width;
  final int height;

  /// 배너를 그리는 위젯. 트리 한 곳에만 넣는다.
  final Widget view;

  final Future<void> Function() _dispose;

  /// 네이티브 광고를 해제한다.
  Future<void> dispose() => _dispose();
}
