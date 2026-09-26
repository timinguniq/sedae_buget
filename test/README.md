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

- 모킹 라이브러리를 쓰지 않는다.
- **서버는 Stub 하나다.** 화면·provider·저장소 테스트는 모두 `test/helper/stub_server.dart`의 `StubServer`를 거쳐 실제 저장소 구현 → 실제 retrofit 명세 → 앱이 local 환경에서 쓰는 `StubApiInterceptor`로 간다. 운영의 local 환경과 같은 배선(`connectToServer`: 토큰 인터셉터 → Stub)이다. 저장소 인터페이스를 손으로 구현한 fake는 두지 않는다(예외: domain usecase 테스트).
- 준비는 실제 API로 한다: `server.seed(profile:, categories:, transactions:)`(kakao로 로그인한 뒤 심는다). Stub의 규칙(사용자 카테고리 검증·상위 분류 맞춤 등)을 지나므로 서버가 만들 수 없는 상태는 만들 수 없다 — 그런 상태의 규칙은 entity 테스트에서 본다.
- 서버 장애·느린 응답은 Stub 앞의 `server.faults`(`test/helper/server_faults.dart`)로 흉내 낸다: `fail(method, pathPrefix, reason:, times:)`, `hold(...)`, 요청 수 `count(...)`. 또래 통계 값은 `StubServer(peerStats: …)`로 준다.
- presentation 테스트는 `fakeContainer(server: …)`로 의존성 seam(`service/*_provider.dart`)을 그 서버의 저장소로 바꾼다. 서버 밖의 재료(광고·원격 설정·테마 저장소·앱 종료)만 `test/helper/fakes.dart`의 fake다. 전역 `get_it`은 쓰지 않는다.
- 위젯 테스트(FakeAsync)에서 Dio 요청은 가짜 시간이 흘러야 끝난다. 준비는 `tester.seedServer(…)`, 위젯 밖 요청은 `tester.untilDone(future)`, 화면이 응답을 다 받아 그릴 때까지는 `tester.settle()`을 쓴다(`pumpAndSettle`은 막 그린 위젯이 보낸 요청을 기다리지 않는다). `runAsync`(진짜 시간)로 준비하면 이후 요청이 끝나지 않는다.
- 실패 처리(오류 응답·깨진 본문·시간 초과)의 번역은 `test/helper/fake_http_adapter.dart`의 `FakeHttpAdapter`로 검증한다. 인터셉터로 만든 가짜 응답(Stub·`faults`)은 Dio 자체의 응답 처리(오류 문구·본문 해석)를 건너뛰어 실제와 다르다.
- 서버 계약(경로·상태코드·검증)은 `test/contract/api_contract.dart` suite가 본다. 경로·바디를 문자열 그대로 적고, 지금은 Stub에 돌린다(`stub_contract_test.dart`). 설명은 `docs/api-contract.md`.

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
