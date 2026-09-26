# 아키텍처

레이어드(클린) 아키텍처. 의존성은 바깥에서 안쪽(`entity`)으로만 흐른다.

**규칙의 기준은 `test/architecture/layer_dependency_test.dart`다.** 이 문서는 그 테스트가 강제하는 내용을 설명한다. 둘이 다르면 테스트가 맞고 문서를 고친다. 규칙을 바꿀 때는 테스트와 이 문서를 함께 바꾼다.

## 레이어와 책임

| 경로 | 책임 |
|---|---|
| `lib/entity/` | 순수 도메인 모델·값 객체·결과 타입(`Result`). Flutter와 다른 레이어를 모른다 |
| `lib/domain/` | `repository/`(리포지토리 등 **인터페이스**), `usecase/`(유스케이스 — 저장소를 부르는 흐름. 계산 규칙은 `entity`에 둔다), `manager/`(앱 전역 상태를 쥐는 도메인 객체 — 아직 없음). `entity`에만 의존 |
| `lib/data/` | `data_source/remote/`(retrofit **명세**와 Stub API), `data_source/local/`(로컬 저장), `dto/`(서버 JSON 형식과 엔티티 변환), `repository_impl/`(실제 통신: 명세 호출·DTO↔엔티티 변환·오류 변환) |
| `lib/core/` | 기술 기반: HTTP 클라이언트, 로컬 저장소, 설정, 광고, 분석, 로깅, DI |
| `lib/presentation/` | 화면(`page/`), 라우팅(`route/`), 공용 위젯(`widget/`), 앱 서비스(`service/`) |
| `lib/theme/` | 디자인 토큰(`foundation/`), 공용 컴포넌트(`component/`), 리소스 |

- 폴더 구성: `data`는 `data_source`(`local`·`remote`)·`dto`·`repository_impl`, `domain`은 `manager`·`repository`·`usecase`로만 나눈다.
- 원격 API: `data_source/remote/*_api.dart`는 retrofit 애너테이션으로 엔드포인트만 선언하고 DTO만 주고받는다. 호출과 실패 번역(`repository_impl/api_call.dart`의 `guardApi`)·엔티티 변환은 `repository_impl`이 한다. 명세나 DTO를 바꾸면 코드 생성을 다시 실행한다.
- 서버 연결: 어느 서버로 보낼지(환경·주소), 인터셉터 순서, 빌드별 요청 로그는 `core/http_client/server_connection.dart`의 `connectToServer`만 정한다. local 환경이면 Stub이 서버 대신 답하고, local이 아닌데 주소가 비었으면 시작할 때 멈춘다. release 빌드는 요청 로그를 남기지 않는다.
- 오류 규약: `domain/repository`의 모든 메서드는 `Result<T>`를 돌려준다(`test/architecture/layer_dependency_test.dart`가 강제). 실패 이유는 `FailureReason` 도메인 enum이고, HTTP 상태코드·전송 오류 코드는 `repository_impl/api_call.dart`에서 번역돼 domain으로 넘어가지 않는다. 서버가 준 도메인 코드(`CATEGORY_DUPLICATE` 등)만 `ErrorResult.code`로, 서버가 쓴 문구만 `ErrorResult.message`로 남는다. 저장소는 던지지 않는다 — 해석할 수 없는 응답도 `guardApi`가 server 실패로 바꾸고, 실패가 값인 경우(프로필 없음 `PROFILE_NOT_FOUND`, `/me` 401 = 로그아웃)도 `guardApi`의 `recover`로만 정한다. 화면은 provider 안에서 `Result.unwrap()`으로 `AsyncValue` 오류로 바꾸거나, 변경 작업이면 `Result`를 그대로 받아 문구를 띄운다. 사용자에게 보이는 실패 문구는 `presentation/widget/common/failure_message.dart`의 `failureMessage`(하던 일 + 이유)만 정하고, 서버 문구는 conflict·invalid일 때만 이유로 쓴다. 불러오기 실패 화면은 `LoadErrorView`를 쓰고, 다시 시도는 장부의 `reload`가 한다.
- 상태 관리: Riverpod. 통신이 필요한 화면은 `page/<기능>/<화면>.view_model.dart`에 Notifier·provider를 둔다. 여러 화면이 같은 서버 상태를 볼 때는 그 상태를 가진 화면의 viewmodel을 함께 쓴다(예: 세션 `login.view_model.dart`).
  - 장부: 로그인 세션에 묶인 가계부 데이터(이달 거래·최근 6개월 추이·사용자 카테고리)는 `page/budget/ledger.view_model.dart`에 둔다. 세션이 바뀌면 다시 읽고 로그인 전에는 비어 있다. 변경 뒤 무엇을 다시 읽을지도 여기서만 정한다(화면은 `ref.invalidate`하지 않는다). 보고 있는 달(`selectedMonthProvider`)은 모든 탭이 함께 보고 이번 달보다 뒤로 가지 않으며, 화면은 그 이름을 `viewedMonthNameProvider`('이번 달'·'M월')로 부른다.
  - 보고 있는 달: 달의 합계·건수·분류별 지출·필터·분석 조각·소득·잔액·저축률과 거래 이름은 `entity/budget/viewed_month.dart`의 `ViewedMonth`가 정한다. 수입은 카테고리가 없어 분류별 집계·건수·필터에 들지 않는다. 소득은 프로필 월소득(없으면 이달 수입 합계)이고 잔액·저축률의 기준이다. 장부의 `viewedMonthProvider`가 이 값을 만든다.
  - 이달 개요: 달을 보여주는 화면(홈·비교·내역·리포트·분석)은 `budget_home.view_model.dart`의 `monthOverviewProvider` 하나를 읽는다. 보고 있는 달(`ViewedMonth`)에 또래 통계를 붙이고, 또래 초과 판정과 또래 통계를 못 읽었을 때 무엇을 뺄지를 여기서 정한다.
  - 거래의 카테고리(표시 이름·기본 분류)는 `entity/budget/category_catalog.dart`의 `CategoryCatalog`로만 판정한다.
  - 또래 비교: 내 금액과 또래 평균의 비교(더·덜·비슷, %, 배율, 크게 넘음)는 `entity/peer/peer_comparison.dart`의 `PeerComparison`이 정하고, `PeerStats`가 월 합계·분류별·가장 큰 차이를 이 값으로 내준다. 또래 값이 없으면(평균 0·빠짐) 비교는 null이고, 표본이 없으면 순위(`PeerStats.rankOf`)도 null이다. 위젯은 받은 값을 그리기만 한다.
  - 거래 입력: 입력 화면의 규칙(카테고리 선택·저장 가능 여부·저장할 거래)은 `entity/budget/transaction_draft.dart`의 `TransactionDraft`가 가진다. 장부의 `save(draft)`가 추가·수정을 정하고, 다 불러온 사용자 카테고리 목록으로 카테고리를 맞춘다(지워진 사용자 카테고리는 기본 분류로).
  - 세션 게이트: 앱이 어디로 갈지는 `route/auth_gate.dart`의 `SessionGate`(확인 중·연결 안 됨·로그아웃·프로필 필요·준비됨)와 순수 함수 `sessionRedirect`만 정한다. 인증·프로필 확인에 실패하면 로그아웃·프로필 없음이 아니라 '연결 안 됨'(`/unreachable`, 다시 시도)이다. 스플래시·온보딩·로그인 화면은 행선지를 고르지 않는다(`context.go`로 게이트 화면을 고르지 않는다).
  - 세션 만료: 서버가 저장된 토큰을 거부하면(401) `core/http_client/auth_token_interceptor.dart`가 토큰을 지우고 `SessionExpiry`로 알린다. 이 신호는 `AuthRepository.sessionExpired`로 domain에 드러나고, `AuthNotifier`가 로그아웃 상태로 바꾼 뒤 로그인 화면이 안내한다.
  - 앱 이용 가능 여부(점검·업데이트): 판정은 `entity/core/app_status.dart`의 `AppStatus.of`, 재료(원격 설정·빌드 번호)는 `core/app_config/remote_config.dart`의 `AppStatusSource`, 안내는 `page/initial/app_status_dialog.dart`가 한다. 앱을 켤 때는 스플래시가, 쓰는 중 원격 설정이 바뀌면 `MyApp`이 안내한다.
- DI: `get_it`. 등록은 composition root인 `lib/core/dependency_injection/`에서만 한다. composition root는 data·domain 구현을 모두 알기 때문에 `main.dart`와 `presentation/service/*_provider.dart`만 import하고, `core/core.dart` 배럴도 다시 내보내지 않는다(배럴을 import한 파일이 전이로 data·domain에 묶이지 않게). 화면이 의존성을 얻는 **seam은 `presentation/service/*_provider.dart`** 하나다(`dependency_provider.dart`·`ad_provider.dart`·`theme_mode_provider.dart`). viewmodel·페이지는 `ref.watch/read(…Provider)`로만 얻고 locator를 직접 부르지 않는다. 테스트는 전역 locator를 등록하는 대신 이 provider를 `overrideWithValue`로 바꾼다.
- 테마: Material 테마는 `theme/material_theme.dart`의 `materialTheme(AppTheme)`가 토큰으로 만든다. 사용자가 고른 모드(시스템·라이트·다크)는 `presentation/service/theme_mode_provider.dart`의 `themeModeProvider`가 쥐고, `core/local_storage/theme_mode_store.dart`가 앱을 켤 때 읽어 둔 저장소에서 동기로 읽어 첫 화면부터 그 모드로 그린다.
- 라우팅: `go_router` (`lib/presentation/route/`).
- 코드 생성: `freezed`, `json_serializable`, `retrofit_generator`. 생성 파일(`*.g.dart`, `*.freezed.dart`)은 커밋하며, 의존성 검사에서는 제외한다.

## 허용·금지 의존성

| 레이어 | import 금지 |
|---|---|
| `entity` | `core`, `domain`, `data`, `presentation`, `theme`, `package:flutter/` |
| `domain` | `data`, `presentation`, `core`, `theme`, `package:flutter/` |
| `data` | `presentation`, `theme`, `package:flutter/`, 로컬 저장 기술(`drift`, `shared_preferences`, `flutter_secure_storage`) — 단 `lib/data/data_source/local/`은 허용 |
| `core` | `presentation`, `theme`. `domain`, `data` — 단 `lib/core/dependency_injection/`(composition root)는 허용 |
| `presentation` | `data` 구현체. DI(`core/dependency_injection`, `core/core.dart`)는 `service/*_provider.dart`에서만 접근 |
| 모든 레이어 | `core/dependency_injection` — 단 composition root 자신과 `presentation/service/*_provider.dart`는 허용(`main.dart`는 레이어 밖) |
| `presentation/page` | `shared_preferences` 직접 사용 |
| `theme` | `presentation`, `domain`, `data` |
| `domain`·`entity`·`presentation`·`theme` | `package:dio/` (HTTP는 `core`·`data`에만) |

## 예시

```dart
// 허용: viewmodel이 provider seam에서 유스케이스를 얻는다 (lib/presentation/page/budget/ledger.view_model.dart)
import 'package:sedae_budget/domain/usecase/category_usecase.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';
// CategoryUsecase get _usecase => ref.read(categoryUsecaseProvider);

// 금지: 페이지·viewmodel이 locator를 직접 부른다 → service/*_provider.dart를 거친다
// 금지: presentation이 data 구현체를 import한다 → domain 인터페이스에 의존한다
import 'package:sedae_budget/data/repository_impl/category_repository_impl.dart';

// 금지: domain이 Flutter나 core를 안다
import 'package:flutter/material.dart';
```

## 도구가 못 잡는 경계

import 규칙은 문자열 검사라 의미적 위반은 잡지 못한다. 아키텍처 검증(`AGENTS.md`의 검증 절차)에서 diff로 확인한다.

- `domain`·`entity`에 화면·위젯 개념(색, 문구 포맷, 라우트 이름)이 들어오지 않는가
- viewmodel 밖에서 DI를 우회해 접근하지 않는가(전역 변수, 정적 접근자 등)
- `data`의 JSON·API 세부(DTO 포함)가 `domain` 인터페이스 시그니처로 새지 않는가
- `data_source/remote` 명세에 호출 로직·엔티티 변환이 들어가지 않는가(명세는 선언만)
- 화면·집계가 거래의 카테고리를 `CategoryCatalog` 밖에서 판정하지 않는가(`BudgetCategory.fromId(tx.categoryId)`를 직접 쓰지 않는다)
- 화면이 또래 비교를 `PeerComparison` 밖에서 판정하지 않는가(`mine > peer`·`avgByCategory[c]`를 직접 견주지 않는다)
