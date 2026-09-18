# 개발 하네스

코드 변경을 일관된 절차로 검사하기 위한 지침·검사 스크립트·훅·CI 구성이다. 작업 지침은 `AGENTS.md`, 구조 규칙은 `docs/architecture.md`, 테스트 규칙은 `test/README.md`에 있다.

## 구성

| 파일 | 책임 |
|---|---|
| `tool/commit_gate.sh` | 공통 게이트. 커밋 대상 내용을 검사하고 실패를 호출자에게 전달 |
| `.githooks/pre-commit` | 실제 Git 훅. 커밋 대상 작업 트리의 게이트를 실행 |
| `tool/agent_pre_commit.py` | Claude Code·Codex 공용 `PreToolUse` 어댑터 |
| `.claude/settings.json`, `.codex/hooks.json` | 두 도구의 훅 등록 |
| `.claude/agents/regression-verifier.md` | Claude Code 회귀 검증 서브에이전트 |
| `tool/test/*_test.py` | 하네스 자체 테스트(임시 Git 저장소 + 가짜 flutter) |
| `.github/workflows/ci.yml` | CI: 하네스 테스트 + 게이트 |

## 새 clone·새 worktree 준비

Git 로컬 설정과 gitignore된 파일은 clone으로 전달되지 않는다. clone마다 한 번 실행한다.

```bash
flutter pub get                                  # .dart_tool/ 생성
touch .env                                       # 실제 값이 있으면 그 파일을 둔다(커밋 금지)
chmod +x tool/commit_gate.sh tool/agent_pre_commit.py .githooks/pre-commit
git config --local core.hooksPath .githooks
```

- `core.hooksPath`는 저장소 단위 설정이라 연결된 worktree에도 적용된다. 다만 worktree마다 `flutter pub get`과 `.env`는 따로 필요하다.
- 이미 다른 `core.hooksPath`를 쓰고 있다면 덮어쓰지 말고, 그 경로의 `pre-commit`에서 `tool/commit_gate.sh`를 호출하도록 병합한다.
- Codex는 프로젝트 훅을 **신뢰 승인 후에만** 실행한다. 프로젝트를 신뢰한 뒤 Codex에서 `/hooks`로 `.codex/hooks.json`의 훅을 검토·승인한다. 훅 내용이 바뀌면 다시 승인해야 한다. Claude Code는 별도 승인 없이 적용된다.

## 활성 검사

게이트는 아래를 순서대로 실행하고, 하나라도 실패하면 사유를 출력하고 0이 아닌 코드로 끝난다. 판정은 출력 문구 검색이 아니라 **도구의 종료 코드**로 한다.

| 검사 | 명령 | 정책 |
|---|---|---|
| 필수 도구·입력 | `git`, `flutter`, `.dart_tool/package_config.json`, `.dart_tool/package_graph.json`, `.env` 존재 확인 | 하나라도 없으면 이유를 표시하고 차단 |
| 정적 분석 | `flutter analyze --no-pub --no-fatal-warnings --no-fatal-infos` | **오류만 차단.** 경고·정보는 허용 |
| 테스트 | `flutter test --no-pub` | 실패·실행 오류·테스트 0개 모두 차단 |
| 레이어 의존성 | `test/architecture/layer_dependency_test.dart` | 위 테스트 실행에 포함 |

### 무엇을 검사하는가: 커밋 대상 내용

게이트는 작업 디렉터리가 아니라 **Git 인덱스(커밋될 내용)** 를 임시 디렉터리에 풀어(`git checkout-index`) 그 안에서 검사하고, 끝나면 지운다.

- stage한 뒤 작업 디렉터리에서만 고친 오류 → 차단된다(커밋될 내용에 오류가 있으므로).
- stage하지 않은 수정, 미추적 파일 → 커밋에 들어가지 않으므로 검사하지 않는다. 반대로 새 파일을 `git add`하지 않아 커밋 내용만으로는 깨지는 경우는 차단된다.
- `git commit -a`, `git commit <경로>` → Git이 넘겨주는 임시 인덱스(`GIT_INDEX_FILE`)를 그대로 따른다.
- 첫 커밋(`HEAD` 없음), 일반 커밋, CI 모두 **항상 스냅샷 전체**를 검사한다. 변경 파일만 골라 검사하지 않으므로 비교 기준 커밋이 필요 없다. CI의 깨끗한 체크아웃에서는 인덱스가 체크아웃한 커밋과 같다.
- 인덱스에 없지만 검사에 필요한 로컬 입력(위 표의 `.dart_tool` 2개 파일과 `.env`)만 스냅샷에 복사한다. 목록은 `tool/commit_gate.sh`의 `LOCAL_INPUTS`다. gitignore된 빌드 입력이 새로 생기면 여기에 추가한다.

### Git 훅

- 훅은 자기 파일 위치를 프로젝트 루트로 가정하지 않는다. `git rev-parse --show-toplevel`로 **커밋 대상 작업 트리**를 구해 그 트리의 게이트를 실행하며, 그 트리에 게이트가 없으면 이유를 표시하고 차단한다.
- `git -C`, `git -c`, 별칭, IDE, 일반 터미널 등 모든 커밋 경로가 이 훅을 거친다.

### 에이전트 훅

`PreToolUse`(Bash) 훅이 `tool/agent_pre_commit.py`를 실행한다. 두 도구의 규약은 같다: stdin JSON의 `tool_input.command`, 종료 코드 2 = 차단(사유는 stderr). 어댑터 실행 자체가 실패해도 차단되도록 등록 명령 끝에 `|| exit 2`를 둔다.

어댑터는 **보조 검사**다. `git commit`이 아니면 즉시 통과시키고, `git commit`이면 다음만 확인한다.

1. 이 저장소(연결된 worktree 포함)의 커밋인가. 다른 저장소의 커밋은 관할이 아니다.
2. 훅 우회(`--no-verify`, `-n`, 그리고 `-c`·`--config-env`·`GIT_CONFIG_KEY_n`으로 명령 안에서 `core.hooksPath` 변경)를 쓰지 않는가.
3. `core.hooksPath`가 등록되어 있고, 대상 트리의 `pre-commit`이 실행 가능하며 `tool/commit_gate.sh`를 호출하는가.

어댑터가 게이트를 직접 실행하지 않는 이유:

- `PreToolUse`는 명령 실행 **전**에 발동한다. 에이전트가 흔히 쓰는 `git add -A && git commit …`에서는 그 시점의 인덱스가 최종 커밋 내용이 아니라서, 여기서 검사하면 엉뚱한 내용을 검사한다. 정확한 시점은 Git 훅뿐이다.
- 중복 실행 측정: 게이트 1회 약 20초(분석 약 2초 + 스냅샷 테스트 약 18초). 어댑터에서도 돌리면 에이전트 커밋마다 약 40초가 된다. 현재 구성은 어댑터 약 0.02초(일반 명령)·0.05초(커밋 명령) + Git 훅의 게이트 1회로, **같은 검사의 중복 실행은 없다.**

한계: 별칭(`git ci`)·래퍼 스크립트를 통한 커밋은 어댑터가 감지하지 못한다. 그 경로도 Git 훅은 실행되지만 우회 옵션 차단은 적용되지 않는다. Claude Code는 `if: "Bash(git *)"`로 git 명령에만 어댑터를 실행하고, Codex는 모든 Bash 명령에 실행한다.

## 제외한 검사

| 검사 | 제외 사유 | 도입 시점 |
|---|---|---|
| 경고를 오류로 처리 | 기존 코드에 경고가 남아 있다(생성 파일의 `duplicate_ignore`, 미사용 import·선언). 고치는 일은 하네스 설정 범위 밖 | 기존 경고를 정리한 뒤 `--no-fatal-warnings` 제거 |
| 별도 의존성 검사기(`tool/dep_guard.sh`) | 같은 규칙을 `test/architecture/`가 이미 강제하고 게이트에 포함된다. 중복 | 규칙이 import 문자열 검사로 표현되지 않을 때 |
| 의존성 현황 측정(`tool/dep_audit.sh`) | 필요한 측정이 없다 | 패키지 정리·업그레이드 작업 때 |
| 커버리지 임계값 | 기준 수치와 분모·제외 규칙(생성 파일, `main.dart`, 테마 리소스)을 아직 정하지 않았다 | 기준을 정한 뒤 `flutter test --coverage` 결과를 게이트에서 판정 |
| 복잡도·CRAP | 커버리지에 의존하고 Dart AST 계산기를 새로 만들어야 한다. 현재 규모에서 효용이 낮다 | 커버리지 도입 이후 |
| 편집 사전 훅(짝 테스트 확인) | 소스와 테스트 경로가 1:1로 대응하지 않는다(`test/README.md`). 파일 존재가 테스트 선행 실행을 증명하지도 않는다 | 테스트 배치를 미러 구조로 통일하면 |
| `prepare-commit-msg` | 이슈 번호 등 메시지에 강제할 정책이 없다(이슈 추적 미사용) | 이슈 추적 도입 시 |
| 변경 파일만 검사 | 전체 검사가 약 20초라 기준 커밋 계산의 복잡도를 들일 이유가 없다 | 게이트가 체감상 느려지면 |
| Codex 전용 검증 에이전트 파일 | 검증 절차를 `AGENTS.md`에 두어 Codex가 직접 수행한다 | Codex 서브에이전트가 필요해지면 |
| 뮤테이션 자동화 도구 | `AGENTS.md`의 수동 절차(임시 복제본)로 수행한다 | 반복 빈도가 높아지면 |

## CI

`.github/workflows/ci.yml`이 PR과 `main` push에서 실행된다: `flutter pub get` → 빈 `.env` 생성 → 하네스 테스트 → `bash tool/commit_gate.sh`. 로컬 훅과 **같은 게이트**를 호출하므로 검사 명령이 두 곳에서 어긋나지 않는다.

- 실패를 무시하는 설정(`continue-on-error`, `|| true`)을 두지 않는다.
- Flutter 버전은 워크플로의 `flutter-version`에 고정한다. 로컬 SDK를 올리면 함께 올린다.
- CI는 로컬 훅이 없는 clone·우회된 커밋에 대한 최종 안전망이다.

## 검증 방법

```bash
python3 -m unittest discover -s tool/test -p '*_test.py' -v   # 하네스 테스트
bash tool/commit_gate.sh                                      # 현재 인덱스 검사
```

하네스 테스트가 실제로 발견·실행됐는지(0개가 아닌지) 확인한다. 하네스 테스트는 가짜 flutter로 **호출·분기**를 검증한다: 정상 통과, 분석 오류, 분석기 실행 실패, 테스트 실패, 도구·입력 부재, stage와 작업 디렉터리 불일치, 첫 커밋, `git -C`/`git -c`/별칭, `commit -a`, worktree, 게이트 없는 트리, 어댑터의 통과·차단·우회 감지.

실제 SDK 확인은 하네스를 바꿀 때마다 임시 clone에서 수행한다: 타입 오류 stage → 차단, 실패 테스트 → 차단, `domain`에 `package:flutter` import → 차단, 경고만 있는 변경 → 통과, 미추적 파일의 오류 → 통과.

## 실패했을 때

| 메시지 | 조치 |
|---|---|
| `flutter를 찾을 수 없습니다` | Flutter SDK 설치·PATH 확인. IDE에서 커밋한다면 IDE의 PATH도 확인 |
| `필수 로컬 파일이 없습니다: .dart_tool/…` | `flutter pub get` |
| `필수 로컬 파일이 없습니다: .env` | `.env`를 준비(값이 없으면 `touch .env`) |
| `정적 분석 실패` | 출력의 `error •` 줄을 고친다. 작업 디렉터리에서 고쳤다면 `git add`로 다시 stage |
| `테스트 실패` | 출력의 `[E]` 테스트를 고친다. 로컬에서는 통과하는데 게이트에서만 실패하면 `git add`하지 않은 파일이 있는지 확인 |
| `인덱스 내용을 내보내지 못했습니다` | 병합 충돌을 먼저 해결 |
| `이 작업 트리에 게이트가 없습니다` | 하네스가 들어간 `main`을 병합·rebase |
| `agent_pre_commit: 차단 — core.hooksPath…` | `git config --local core.hooksPath .githooks` |
| `agent_pre_commit: 차단 — … 건너뛸 수 없습니다` | 우회 옵션을 빼고 게이트가 막는 원인을 고친다 |

훅을 우회하지 않는다. 게이트 자체가 잘못됐다면 게이트를 고치고 하네스 테스트를 함께 고친다.

## 알려진 한계

- `core.hooksPath`가 상대 경로라, 하네스 도입 **이전** 커밋을 체크아웃한 트리에는 `.githooks/`가 없어 Git 훅이 실행되지 않는다. 에이전트 커밋은 어댑터가 막지만 일반 터미널 커밋은 CI에서만 걸린다.
- Git 훅은 로컬에서 `--no-verify`로 건너뛸 수 있다. 사람의 우회는 CI가 잡는다.
- 교차 검증은 두 도구가 모두 사용 가능할 때만 성립한다. 한쪽을 쓸 수 없을 때의 처리는 `AGENTS.md`에 있다.
