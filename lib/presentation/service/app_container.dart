import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// 앱의 provider 컨테이너. 앱(`main.dart`)과 테스트(`fakeContainer`)가 이것으로 만들어 같은 정책으로 돈다.
///
/// 실패한 provider를 다시 부르지 않는다. Riverpod 기본값은 조용히 10번(약 38초) 다시 불러서, 그동안 화면은
/// 오류 대신 불러오는 중으로 보이고 `.future`도 끝나지 않는다. 다시 읽는 것은 사용자가 누르는 '다시 시도'
/// (달 화면은 장부, 세션 확인은 연결 안 됨 화면)가 한다.
ProviderContainer appContainer({List<Override> overrides = const []}) =>
    ProviderContainer(retry: (_, _) => null, overrides: overrides);
