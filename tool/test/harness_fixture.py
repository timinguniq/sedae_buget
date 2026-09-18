"""하네스 테스트 공통 기반: 임시 Git 저장소와 가짜 flutter.

가짜 flutter는 호출·분기 검증용이다. 실제 SDK와 실제 위반 코드로 하는 확인 절차는
docs/harness.md에 있다.
"""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
HARNESS_FILES = ["tool/commit_gate.sh", "tool/agent_pre_commit.py", ".githooks/pre-commit"]

# 호출 인자와 실행 위치를 기록하고, 표식 문자열이나 환경 변수로 실패를 흉내 낸다.
FAKE_FLUTTER = """#!/bin/bash
echo "$* @ $PWD" >> "$FAKE_FLUTTER_LOG"
[ -f .env ] && [ -f .dart_tool/package_config.json ] && [ -f .dart_tool/package_graph.json ] || {
  echo "fake flutter: 로컬 입력이 복사되지 않았습니다" >&2
  exit 3
}
[ -z "${GIT_DIR:-}${GIT_INDEX_FILE:-}${GIT_WORK_TREE:-}" ] || {
  echo "fake flutter: 훅의 GIT_* 변수가 검사 도구로 새어 들어왔습니다" >&2
  exit 4
}
case "$1" in
  analyze) grep -rqs ANALYZE_VIOLATION lib && exit 1; exit "${FAKE_ANALYZE_EXIT:-0}" ;;
  test) grep -rqs TEST_VIOLATION test && exit 1; exit "${FAKE_TEST_EXIT:-0}" ;;
esac
exit 64
"""


class HarnessTestCase(unittest.TestCase):
    def setUp(self):
        # 공백이 들어간 경로에서도 동작해야 한다.
        self.tmp = Path(tempfile.mkdtemp(prefix="harness test ")).resolve()
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)

        bin_dir = self.tmp / "bin"
        bin_dir.mkdir()
        fake = bin_dir / "flutter"
        fake.write_text(FAKE_FLUTTER)
        fake.chmod(0o755)
        self.flutter_log = self.tmp / "flutter.log"

        # 개인 Git 설정과, 훅 안에서 실행될 때 물려받는 GIT_* 변수로부터 격리한다.
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.update(
            PATH=f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            FAKE_FLUTTER_LOG=str(self.flutter_log),
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_SYSTEM=os.devnull,
            GIT_AUTHOR_NAME="harness",
            GIT_AUTHOR_EMAIL="harness@example.invalid",
            GIT_COMMITTER_NAME="harness",
            GIT_COMMITTER_EMAIL="harness@example.invalid",
        )
        self.repo = self.make_repo("repo")

    def run_in(self, cwd, *args, env=None, **kwargs):
        return subprocess.run(
            list(args), cwd=cwd, env=env or self.env, capture_output=True, text=True, **kwargs
        )

    def git(self, *args, cwd=None, check=True):
        result = self.run_in(cwd or self.repo, "git", *args)
        if check and result.returncode != 0:
            self.fail(f"git {' '.join(args)} 실패:\n{result.stdout}{result.stderr}")
        return result

    def write(self, relative, content, repo=None):
        path = (repo or self.repo) / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def make_repo(self, name):
        """하네스 스크립트 사본과 훅 등록을 갖춘, 아직 커밋이 없는 저장소."""
        repo = self.tmp / name
        repo.mkdir()
        self.git("init", "-q", "-b", "main", cwd=repo)
        for relative in HARNESS_FILES:
            target = repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(PROJECT_ROOT / relative, target)
            target.chmod(0o755)
        self.write("pubspec.yaml", "name: fixture\n", repo)
        self.write("lib/ok.dart", "void ok() {}\n", repo)
        self.write("test/ok_test.dart", "void main() {}\n", repo)
        self.write(".gitignore", ".env\n.dart_tool/\n", repo)
        self.write_local_inputs(repo)
        self.git("config", "core.hooksPath", ".githooks", cwd=repo)
        self.git("add", "-A", cwd=repo)
        return repo

    def write_local_inputs(self, repo):
        self.write(".env", "ENV=test\n", repo)
        self.write(".dart_tool/package_config.json", "{}\n", repo)
        self.write(".dart_tool/package_graph.json", "{}\n", repo)

    def flutter_calls(self):
        return self.flutter_log.read_text().splitlines() if self.flutter_log.exists() else []

    def head(self, repo=None):
        result = self.git("rev-parse", "--verify", "-q", "HEAD", cwd=repo, check=False)
        return result.stdout.strip() or None
