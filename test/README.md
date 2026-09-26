# 테스트

## 실행

```bash
flutter test                                   # 전체
flutter test test/domain/auth_usecase_test.dart # 파일 하나
flutter test test/architecture                  # 레이어 의존성 규칙만
```

커밋할 때는 Git `pre-commit` 훅이 커밋 대상 내용으로 전체 테스트를 실행한다(`docs/harness.md`).

## 배치와 이름

- 파일 이름은 `*_test.dart`.
- 새 테스트는 대상 소스의 경로를 따라 `test/<레이어>/…`에 둔다. 예: `lib/data/repository_impl/…` → `test/data/repository_impl/…_test.dart`
- 가계부(budget) 기능의 기존 entity·presentation 테스트는 `test/budget/<레이어>/`에 있다. 옮기지 않고 그 자리에서 유지·추가한다.
- 공용 테스트 대역은 `test/helper/`에 둔다.
- 소스와 테스트의 경로가 1:1로 대응하지 않으므로 "짝 테스트 파일 존재" 자동 검사는 하지 않는다.

## 테스트 대역

- 모킹 라이브러리를 쓰지 않는다. `test/helper/fakes.dart`의 **인메모리 fake**(리포지토리 인터페이스 구현)를 쓴다.
- 장부(거래·사용자 카테고리)는 로그인 세션에 묶여 있어 로그인 전에는 비어 있다. 장부를 읽는 테스트는 `fakeContainer(user: testUser, …)`로 로그인한다.
- presentation 테스트는 `fakeContainer`로 의존성 seam(`service/*_provider.dart`)을 fake로 바꾼 뒤 위젯·provider를 검증한다. 전역 `get_it`은 쓰지 않는다.
- HTTP 계층은 실제 서버 대신 Dio `Interceptor`로 검증한다: `StubApiInterceptor`(`lib/data/data_source/remote/stub/`)나 테스트 파일 안의 작은 인터셉터(응답 고정·오류·타임아웃).
- 실패 처리(오류 응답·깨진 본문·시간 초과)는 `test/helper/fake_http_adapter.dart`의 `FakeHttpAdapter`로 검증한다. 인터셉터로 만든 가짜 응답은 Dio 자체의 응답 처리(오류 문구·본문 해석)를 건너뛰어 실제와 다르다.
- 저장소 구현·Stub 계약 테스트는 `test/helper/stub_server.dart`의 `StubServer`를 쓴다. 운영의 local 환경과 같은 배선(`connectToServer`: 토큰 인터셉터 → Stub)으로 조립해 실제 저장소 구현을 내준다. Stub은 사용자마다 데이터를 따로 둔다.

## 종류

| 종류 | 위치 | 비고 |
|---|---|---|
| 단위(entity·domain·data·core) | `test/<레이어>/…` | Flutter 바인딩 없이 실행 |
| 위젯·provider | `test/presentation/…`, `test/theme/…`, `test/budget/presentation/…` | `flutter_test` |
| 아키텍처 | `test/architecture/` | `lib/`의 import를 읽어 레이어 규칙 검사. 규칙 설명은 `docs/architecture.md` |
| 골든·통합 | 없음 | 도입하면 이 표와 `docs/harness.md`를 갱신 |

## 품질 기준

- 버그 수정과 새 로직은 **실패하는 테스트를 먼저 실행**하고, 수정 후 통과를 확인한다. 두 실행 결과를 작업 보고에 남긴다. 테스트 파일이 있다는 사실만으로는 테스트를 먼저 실행했다는 증거가 되지 않는다.
- 테스트는 구현 세부가 아니라 동작을 검증한다.
- 테스트가 0개 실행된 결과는 통과로 보지 않는다.
- 커버리지·복잡도 임계값은 아직 두지 않는다(사유는 `docs/harness.md`).
