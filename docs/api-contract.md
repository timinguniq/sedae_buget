# API 계약 v1

앱과 서버(지금은 앱 안의 Stub, 앞으로 Gleam 서버)가 지키는 HTTP 계약이다.

**기준은 `test/contract/api_contract.dart`다.** 이 문서는 그 suite가 강제하는 내용을 설명한다. 둘이 다르면 suite가 맞고 문서를 고친다. 계약을 바꿀 때는 suite와 이 문서, Stub(`lib/data/data_source/remote/stub/`)을 함께 바꾼다.

- suite는 경로·바디를 앱 코드(`ApiPath`·DTO)를 쓰지 않고 문자열 그대로 적는다. 앱과 Stub이 같은 오타를 나눠 가져도 드러나게 하기 위해서다.
- 지금은 Stub에만 돌린다(`test/contract/stub_contract_test.dart`). 실제 서버에 돌리려면 그 서버를 겨냥하는 `ContractTarget`을 하나 더 만든다. 서버가 테스트 로그인(`idToken`)을 어떻게 받아들일지는 그때 정한다.

## 공통 규칙

- 요청·응답은 JSON(`Content-Type: application/json`).
- 로그인 뒤의 모든 요청에 `Authorization: Bearer <accessToken>`. 없거나 틀리면 401. 토큰 갱신은 v1 범위 밖이다.
- 금액은 원 단위 정수.
- 기본 분류는 통계청 12분류(`categoryId` 1~12)이고 계약 상수다. API로 추가·수정·삭제할 수 없다. 또래 집계는 언제나 이 12분류로 한다.
- enum은 Dart 이름 그대로: `provider` ∈ `kakao|naver|google`, `ageGroup` ∈ `teens|twenties|thirties|forties|fiftiesPlus`, `type` ∈ `expense|income`.
- 모든 일시는 ISO-8601 UTC(`...Z`).
- 성공은 2xx(바디가 없으면 204). 실패는 4xx/5xx와 바디 `{"code": "...", "message": "..."}`.
- 프로필·거래·사용자 카테고리는 로그인한 사용자 것이다. 다른 사용자의 데이터는 보이지 않고, 이름 겹침도 사용자 안에서만 본다.

### 오류 코드

| 상태 | code | 뜻 |
|---|---|---|
| 400 | `VALIDATION` | 바디·쿼리가 아래 규칙에 맞지 않는다 |
| 401 | (서버가 정함. Stub은 `AUTH_002` · `AUTH_004`) | 토큰이 없다 · 토큰이 틀렸다 |
| 403 | `CATEGORY_IMMUTABLE` | 기본 분류를 사용자 카테고리 경로로 건드렸다 |
| 404 | `PROFILE_NOT_FOUND` | 아직 프로필을 만들지 않았다 |
| 404 | `NOT_FOUND` | 없는 경로·거래·카테고리 |
| 409 | `CATEGORY_DUPLICATE` | 같은 사용자 안에서 카테고리 이름이 겹친다 |
| 5xx | (서버가 정함) | 서버 문제. Stub은 기기 저장 실패·자기 결함을 500 `INTERNAL`로 낸다 |

앱은 `code`로 실패 이유를 나누고(`lib/data/repository_impl/api_call.dart`), 사용자에게 보여줄 문구는 앱이 정한다. 서버 `message`는 409·400일 때만 문구로 쓴다.

## 경로

| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/v1/auth/login` | `{"provider":"kakao","idToken":"..."}` | 200 `{"accessToken":"...","user":{"id":"...","provider":"kakao","nickname":"..."}}`. `idToken`이 없거나 `provider`가 틀리면 400 |
| POST | `/v1/auth/logout` | | 204 |
| GET | `/v1/me` | | 200 사용자(로그인 응답의 `user`와 같은 모양) |
| GET | `/v1/me/profile` | | 200 `{"ageGroup":"thirties","monthlyIncome":3000000}` / 404 `PROFILE_NOT_FOUND` |
| PUT | `/v1/me/profile` | `{"ageGroup":"thirties","monthlyIncome":3000000}` | 200 같은 모양 |
| GET | `/v1/transactions?from=<UTC>&to=<UTC>` | `[from, to)` 반개구간. 둘 다 필요 | 200 `[거래…]`(날짜 최신순) |
| PUT | `/v1/transactions/{id}` | 거래 바디 | 201(새 id) / 200(같은 id) 거래 |
| DELETE | `/v1/transactions/{id}` | | 204 / 404 |
| GET | `/v1/categories` | | 200 `[사용자 카테고리…]`(만든 순서) |
| PUT | `/v1/categories/{id}` | `{"name":"반려동물","baseCategoryId":12}` | 201(새 id) / 200(같은 id) 사용자 카테고리 |
| DELETE | `/v1/categories/{id}` | | 204 / 404 |
| GET | `/v1/peer/stats?ageGroup=thirties` | 나이대 필요 | 200 또래 통계 |
| GET | `/v1/peer/generations` | | 200 `[{"ageGroup":"teens","avgMonthlyExpense":800000}, …]`(다섯 나이대) |

## 모양과 검증

### 프로필

- `ageGroup`: 나이대 이름 중 하나.
- `monthlyIncome`: 0 이상 정수.

### 거래

```jsonc
{"id":"c2f1...","amount":12000,"categoryId":7,"date":"2026-09-05T15:00:00.000Z",
 "type":"expense","memo":"버스","customCategoryId":null,
 "createdAt":"2026-09-06T01:02:03.000Z","updatedAt":"2026-09-06T01:02:03.000Z"}
```

- `id`는 클라이언트가 정한다(UUID). 같은 id로 다시 보내면 갱신이라, 저장을 몇 번 시도해도 거래는 하나다.
- `createdAt`·`updatedAt`은 서버가 정한다. 갱신해도 `createdAt`은 그대로다.
- 바디 규칙(어기면 400 `VALIDATION`, 저장하지 않는다):
  - `amount`: 1 이상 정수.
  - `type`: `expense` 또는 `income`.
  - `categoryId`: 지출이면 1~12. 수입은 카테고리가 없어서 정수이기만 하면 된다(앱은 보내지만 쓰지 않는다).
  - `date`: ISO-8601 UTC.
  - `memo`: 문자열 또는 null. 길이 제한은 없다.
  - `customCategoryId`: null이거나 그 사용자의 사용자 카테고리 id. 없는 카테고리면 400.
- `customCategoryId`가 있으면 서버가 `categoryId`를 그 카테고리의 상위 분류로 맞춘다.

### 사용자 카테고리

```jsonc
{"id":"a41c...","name":"반려동물","baseCategoryId":12}
```

- `id`는 클라이언트가 정한다(UUID). 숫자 id는 기본 분류라 만들거나 지울 수 없다(403).
- `name`: 앞뒤 공백을 뺀 1~10자. 같은 사용자 안에서 유일하다(대소문자 무시, 자기 자신은 제외). 겹치면 409.
- `baseCategoryId`: 1~12. 또래 비교가 기본 분류로만 하므로 반드시 있다.
- 상위 분류를 바꾸면 그 카테고리를 쓰던 거래의 `categoryId`도 옮긴다.
- 지우면 그 카테고리를 쓰던 거래의 `customCategoryId`를 null로 되돌린다(`categoryId`는 그대로라 또래 집계는 변하지 않는다).

### 또래 통계

```jsonc
{"ageGroup":"thirties","avgMonthlyExpense":2600000,"avgSavingsRate":0.22,
 "avgByCategory":{"1":390000,"2":52000, /* ... */ "12":130000},
 "samples":[1170000, /* ... */ 4550000]}
```

- `avgByCategory` 키는 `categoryId` 문자열("1"~"12"), 값은 정수. 빠진 분류는 또래 값이 없다는 뜻이다.
- `samples`는 월지출 분포, 오름차순 정수, 최대 99개.
- 앱은 모르는 분류 키를 버린다(서버가 분류를 늘려도 또래 부분 전체가 실패하지 않는다).
