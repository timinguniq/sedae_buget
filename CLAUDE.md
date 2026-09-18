# CLAUDE.md

공통 작업 지침(작업 원칙·개발 명령·완료 기준·커밋 규칙·검증 절차)은 `AGENTS.md`가 기준이다. 아래 import로 그대로 불러온다.

@AGENTS.md

## Claude Code 전용

### Workflow

- 코드 변경(파일 추가/수정/삭제)이 발생하면 커밋 전에 `regression-verifier` 서브에이전트를 호출해 기존 기능이 깨지지 않는지 회귀 검증을 수행한다.
- `regression-verifier`를 호출할 때는 "작업 트리·인덱스를 바꾸는 Git 명령(`git stash`, `checkout`, `reset`, `clean`) 금지"를 프롬프트에 명시한다.
- 교차 코드 리뷰는 Codex가 맡는다: `codex review --uncommitted` (커밋 후라면 `codex review --base main`). 실행하지 못하면 미실행과 사유를 보고한다.

### 훅

- `.claude/settings.json`의 `PreToolUse`(Bash, `git *`) 훅이 `tool/agent_pre_commit.py`를 실행한다. `git commit`일 때만 Git 훅 등록 여부와 우회 옵션을 확인하며, 실제 검사는 Git `pre-commit` 훅이 수행한다(`docs/harness.md`).
- 개인 권한 설정은 `.claude/settings.local.json`에 두고 커밋하지 않는다.
