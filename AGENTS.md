# AGENTS.md

Claude Code와 Codex가 함께 읽는 **공통 작업 지침**이다. 두 도구의 지침이 다르면 이 파일이 기준이다.
도구별 추가 사항은 `CLAUDE.md`(Claude Code)에 둔다. Codex는 이 파일을 직접 읽는다.

- 프로젝트: Flutter 앱 `sedae_budget` (패키지 import 접두어 `package:sedae_budget/`)
- 구조와 의존성 규칙: `docs/architecture.md`
- 테스트 규칙: `test/README.md`
- 하네스(검사·훅·CI) 설명과 실패 해결법: `docs/harness.md`

---

## Working Principles

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### 5. Coding Guidelines

- Adhere to SOLID principles when writing code.
- Utilize OOP design patterns whenever applicable!

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## 개발 명령

프로젝트 루트에서 실행한다.

| 목적 | 명령 |
|---|---|
| 의존성 설치 | `flutter pub get` |
| 정적 분석 | `flutter analyze --no-pub --no-fatal-warnings --no-fatal-infos` |
| 전체 테스트 | `flutter test` |
| 일부 테스트 | `flutter test test/<경로>_test.dart` |
| 코드 생성(freezed·json_serializable) | `dart run build_runner build` |
| 커밋 대상 검사(게이트) | `bash tool/commit_gate.sh` |
| 하네스 자체 테스트 | `python3 -m unittest discover -s tool/test -p '*_test.py' -v` |
| 앱 실행 | `flutter run` (`.env` 필요. 환경 지정은 `--dart-define=env=<이름>`) |

- 분석 정책: **오류만 차단**한다. 경고·정보는 허용하지만 새로 늘리지 않는다.
- 생성 파일(`*.g.dart`, `*.freezed.dart`)은 저장소에 커밋한다. 원본을 바꾸면 코드 생성을 다시 실행하고 결과를 함께 커밋한다.
- 새 clone에서는 `flutter pub get` → `.env` 준비 → `git config --local core.hooksPath .githooks` 순서로 준비한다(`docs/harness.md`).

## 완료 기준

변경을 완료로 보고하려면 다음을 모두 만족해야 한다.

1. 변경과 관련된 테스트를 실행했고 통과한다. 버그 수정·새 로직은 **실패하는 테스트를 먼저 실행한 기록**과 수정 후 통과 기록을 남긴다.
2. `bash tool/commit_gate.sh`(분석 + 전체 테스트 + 레이어 의존성 규칙)가 통과한다.
3. 아래 "검증 절차"를 수행했고, 실행하지 못한 검증은 **미실행과 사유**를 적었다. 미실행을 통과로 표기하지 않는다.
4. 레이어 규칙이나 하네스를 바꿨다면 `docs/architecture.md`·`docs/harness.md`와 해당 테스트를 함께 고쳤다.

## 커밋 규칙

- `main`에 직접 커밋하지 않는다. 작업 브랜치(`feat/…`, `fix/…`, `chore/…`)에서 커밋하고 PR로 병합한다.
- 메시지는 Conventional Commits 형식: `type(scope): 요약` (예: `fix(build): drop nonexistent asset entry`).
- 커밋은 사용자가 요청했을 때만 한다.
- Git 훅을 우회하지 않는다: `--no-verify`, `-n`, 명령 안에서 `core.hooksPath`를 바꾸는 것(`-c`, `--config-env`, `GIT_CONFIG_*`) 금지. 게이트가 막으면 원인을 고친다.
- 개인 권한·인증·세션·API 키(`.env`, `settings.local.json`, keystore 등)는 커밋하지 않는다.

## 검증 절차

구현한 도구가 관련 테스트를 실행한 **뒤에** 아래 순서로 검증한다. 검증 역할은 코드를 고치지 않고 보고만 한다.

| 순서 | 역할 | 범위 | 수행 방법 |
|---|---|---|---|
| 1 | 회귀 검증 | 기존 기능이 깨졌는지 | 분석 + 관련 테스트 + 전체 테스트 + diff 검토. Claude Code는 `regression-verifier` 서브에이전트, Codex는 같은 절차를 직접 수행 |
| 2 | 아키텍처 검증 | 레이어 경계 | `flutter test test/architecture` 실행 후, import 규칙이 못 잡는 의미적 경계(예: domain에 UI 개념 유입, provider 밖 DI 접근 우회)를 diff로 검토 |
| 3 | 코드 리뷰(교차) | 새 코드·테스트의 정확성·단순성 | **구현하지 않은 쪽 도구**가 수행. Claude가 구현 → `codex review --uncommitted`(커밋 후라면 `codex review --base main`). Codex가 구현 → `claude -p "main 대비 변경을 AGENTS.md 기준으로 리뷰해줘. 파일은 수정하지 마."` |
| 4 | 뮤테이션 검증 | 테스트가 결함을 감지하는지 | 1–3이 끝난 뒤 **단독으로**, 아래 절차대로 임시 복제본에서 수행 |

### 뮤테이션 검증 절차

파일을 바꾸는 검증이므로 원본 작업 트리에서 하지 않는다.

1. 원본 상태 기록: `git status --porcelain; git diff | shasum`
2. 검토할 변경을 포함한 복제본 생성: `rsync -a --exclude build/ --exclude .git/ ./ "$tmp/"`
3. 복제본에서 변경된 로직에 결함을 하나씩 주입(조건 반전, 경계값 ±1, 호출 제거 등)하고 관련 테스트를 실행한다. 테스트가 실패하면 감지(killed), 통과하면 생존(survived).
4. 복제본을 지우고 1번 명령을 다시 실행해 원본이 그대로인지 비교한다.
5. 주입한 결함, 실행한 테스트, 감지·생존 결과를 보고한다. 생존한 결함은 테스트를 보강하거나 보강하지 않는 이유를 적는다.

### 한 도구만 쓸 수 있을 때

교차 리뷰를 실행하지 못했다면(호출 권한·모델 접근·사용량 제한 등) 같은 도구의 별도 세션·서브에이전트로 대체하고, **교차 검증 미실행과 사유**를 보고에 적는다.
