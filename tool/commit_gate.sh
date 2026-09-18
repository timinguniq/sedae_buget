#!/usr/bin/env bash
# 공통 커밋 게이트.
# 작업 디렉터리가 아니라 커밋 대상(Git 인덱스) 내용을 임시 디렉터리에 풀어 검사한다.
# 사용: 검사할 작업 트리 안에서 `bash tool/commit_gate.sh`
# 정책·제외 사유·실패 해결법: docs/harness.md
set -euo pipefail

fail() {
  echo "commit_gate: 차단 — $*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || fail "git을 찾을 수 없습니다."
command -v flutter >/dev/null 2>&1 ||
  fail "flutter를 찾을 수 없습니다. Flutter SDK를 설치하고 PATH에 추가하세요."

root="$(git rev-parse --show-toplevel)" || fail "Git 작업 트리 안에서 실행해야 합니다."
cd "$root"

# gitignore되어 인덱스에는 없지만 분석·테스트에 필요한 로컬 입력.
LOCAL_INPUTS=(
  ".dart_tool/package_config.json"
  ".dart_tool/package_graph.json"
  ".env"
)
for f in "${LOCAL_INPUTS[@]}"; do
  [ -f "$f" ] ||
    fail "필수 로컬 파일이 없습니다: $f (.dart_tool → 'flutter pub get', .env → docs/harness.md 참고)"
done

snapshot="$(mktemp -d "${TMPDIR:-/tmp}/commit_gate.XXXXXX")"
trap 'rm -rf "$snapshot"' EXIT

# `git commit -a`나 경로 지정 커밋은 GIT_INDEX_FILE로 임시 인덱스를 넘기므로 그대로 따른다.
git checkout-index --all --prefix="$snapshot/" ||
  fail "인덱스 내용을 내보내지 못했습니다. 해결되지 않은 병합 충돌이 있는지 확인하세요."
for f in "${LOCAL_INPUTS[@]}"; do
  mkdir -p "$snapshot/$(dirname "$f")"
  cp "$f" "$snapshot/$f"
done

# 훅에서 물려받은 GIT_DIR·GIT_INDEX_FILE 등이 스냅샷 안의 도구 실행에 새지 않게 한다.
unset $(git rev-parse --local-env-vars)
cd "$snapshot"

run_check() {
  local name="$1"
  shift
  echo "commit_gate: $name → $*"
  "$@" || fail "$name 실패(종료 코드 $?). 위 출력을 확인하세요."
}

# 정책: 분석 오류만 차단한다. 경고·정보는 허용(docs/harness.md).
run_check "정적 분석" flutter analyze --no-pub --no-fatal-warnings --no-fatal-infos
# 레이어 의존성 규칙(test/architecture)도 이 실행에 포함된다.
run_check "테스트" flutter test --no-pub

echo "commit_gate: 통과"
