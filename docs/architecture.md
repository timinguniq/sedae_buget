# 아키텍처

레이어드(클린) 아키텍처. 의존성은 바깥에서 안쪽(`entity`)으로만 흐른다.

**규칙의 기준은 `test/architecture/layer_dependency_test.dart`다.** 이 문서는 그 테스트가 강제하는 내용을 설명한다. 둘이 다르면 테스트가 맞고 문서를 고친다. 규칙을 바꿀 때는 테스트와 이 문서를 함께 바꾼다.

## 레이어와 책임

| 경로 | 책임 |
|---|---|
| `lib/entity/` | 순수 도메인 모델·값 객체·결과 타입(`Result`). Flutter와 다른 레이어를 모른다 |
| `lib/domain/` | 유스케이스와 리포지토리 **인터페이스**. `entity`에만 의존 |
| `lib/data/` | 리포지토리 구현(API), JSON 변환, `remote/stub/`의 Stub API |
| `lib/core/` | 기술 기반: HTTP 클라이언트, 로컬 저장소, 설정, 광고, 분석, 로깅, DI |
| `lib/presentation/` | 화면(`page/`), 라우팅(`route/`), 공용 위젯(`widget/`), 앱 서비스(`service/`) |
| `lib/theme/` | 디자인 토큰(`foundation/`), 공용 컴포넌트(`component/`), 리소스 |

- 상태 관리: Riverpod. 화면 상태는 각 페이지 폴더의 `*_provider.dart`에 둔다.
- DI: `get_it`. 등록은 composition root인 `lib/core/dependency_injection/`에서만 한다.
- 라우팅: `go_router` (`lib/presentation/route/`).
- 코드 생성: `freezed`, `json_serializable`. 생성 파일(`*.g.dart`, `*.freezed.dart`)은 커밋하며, 의존성 검사에서는 제외한다.

## 허용·금지 의존성

| 레이어 | import 금지 |
|---|---|
| `entity` | `core`, `domain`, `data`, `presentation`, `theme`, `package:flutter/` |
| `domain` | `data`, `presentation`, `core`, `theme`, `package:flutter/` |
| `data` | `presentation`, `theme`, `package:flutter/`, 로컬 저장 기술(`drift`, `shared_preferences`, `flutter_secure_storage`) — 단 `lib/data/remote/stub/`는 Stub 영속화를 위해 저장 기술 허용 |
| `core` | `domain`, `data` — 단 `lib/core/dependency_injection/`(composition root)는 허용 |
| `presentation` | `data` 구현체. DI(`core/dependency_injection`, `core/core.dart`)는 `*_provider.dart`에서만 접근 |
| `presentation/page` | `shared_preferences` 직접 사용 |
| `theme` | `presentation`, `domain`, `data` |
| `domain`·`entity`·`presentation`·`theme` | `package:dio/` (HTTP는 `core`·`data`에만) |

## 예시

```dart
// 허용: provider가 DI에서 유스케이스를 꺼낸다 (lib/presentation/page/budget/category_provider.dart)
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/category_usecase.dart';

// 금지: 페이지·위젯이 locator를 직접 부른다 → *_provider.dart를 거친다
// 금지: presentation이 data 구현체를 import한다 → domain 인터페이스에 의존한다
import 'package:sedae_budget/data/budget/api_category_repository.dart';

// 금지: domain이 Flutter나 core를 안다
import 'package:flutter/material.dart';
```

## 도구가 못 잡는 경계

import 규칙은 문자열 검사라 의미적 위반은 잡지 못한다. 아키텍처 검증(`AGENTS.md`의 검증 절차)에서 diff로 확인한다.

- `domain`·`entity`에 화면·위젯 개념(색, 문구 포맷, 라우트 이름)이 들어오지 않는가
- provider 밖에서 DI를 우회해 접근하지 않는가(전역 변수, 정적 접근자 등)
- `data`의 JSON·API 세부가 `domain` 인터페이스 시그니처로 새지 않는가
