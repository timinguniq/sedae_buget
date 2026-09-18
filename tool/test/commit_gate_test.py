"""tool/commit_gate.sh 와 .githooks/pre-commit 검증.

실행: python3 -m unittest discover -s tool/test -p '*_test.py' -v
"""

import os
import shutil
import unittest

from harness_fixture import HarnessTestCase

ANALYZE_BAD = "// ANALYZE_VIOLATION\n"
TEST_BAD = "// TEST_VIOLATION\n"


class CommitGateTest(HarnessTestCase):
    """게이트 단독 실행."""

    def run_gate(self, env=None):
        return self.run_in(self.repo, "bash", "tool/commit_gate.sh", env=env)

    def test_clean_index_passes_and_checks_a_snapshot(self):
        result = self.run_gate()

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.flutter_calls()
        self.assertEqual(len(calls), 2, calls)
        self.assertTrue(
            calls[0].startswith("analyze --no-pub --no-fatal-warnings --no-fatal-infos @ "), calls
        )
        self.assertTrue(calls[1].startswith("test --no-pub @ "), calls)
        for call in calls:
            self.assertNotEqual(call.split(" @ ")[1], str(self.repo), "작업 트리가 아닌 스냅샷을 검사해야 한다")

    def test_analysis_error_blocks(self):
        self.write("lib/bad.dart", ANALYZE_BAD)
        self.git("add", "-A")

        result = self.run_gate()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("정적 분석 실패", result.stderr)

    def test_analyzer_execution_failure_blocks(self):
        result = self.run_gate(env={**self.env, "FAKE_ANALYZE_EXIT": "70"})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("정적 분석 실패(종료 코드 70)", result.stderr)

    def test_test_failure_blocks(self):
        self.write("test/bad_test.dart", TEST_BAD)
        self.git("add", "-A")

        result = self.run_gate()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("테스트 실패", result.stderr)

    def test_missing_flutter_blocks_with_reason(self):
        without_flutter = os.pathsep.join(
            d for d in self.env["PATH"].split(os.pathsep) if not shutil.which("flutter", path=d)
        )

        result = self.run_gate(env={**self.env, "PATH": without_flutter})

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("flutter를 찾을 수 없습니다", result.stderr)

    def test_missing_local_input_blocks_with_reason(self):
        for relative in [".dart_tool/package_config.json", ".dart_tool/package_graph.json", ".env"]:
            with self.subTest(relative):
                self.write_local_inputs(self.repo)
                (self.repo / relative).unlink()

                result = self.run_gate()

                self.assertNotEqual(result.returncode, 0)
                self.assertIn(f"필수 로컬 파일이 없습니다: {relative}", result.stderr)
        self.assertEqual(self.flutter_calls(), [], "입력이 없으면 검사를 시작하지 않는다")

    def test_staged_violation_is_caught_even_if_worktree_is_fixed(self):
        bad = self.write("lib/bad.dart", ANALYZE_BAD)
        self.git("add", "-A")
        bad.write_text("void fixed() {}\n")  # 고쳤지만 stage하지 않음

        self.assertNotEqual(self.run_gate().returncode, 0)

    def test_unstaged_and_untracked_violations_are_not_part_of_the_commit(self):
        self.write("lib/ok.dart", ANALYZE_BAD)  # stage된 뒤의 수정
        self.write("lib/untracked.dart", ANALYZE_BAD)

        result = self.run_gate()

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_snapshot_is_removed_afterwards(self):
        scratch = self.tmp / "scratch"
        scratch.mkdir()
        self.write("lib/bad.dart", ANALYZE_BAD)
        self.git("add", "-A")

        self.run_gate(env={**self.env, "TMPDIR": str(scratch)})

        self.assertEqual(list(scratch.iterdir()), [])


class PreCommitHookTest(HarnessTestCase):
    """실제 `git commit`이 훅을 거쳐 게이트를 실행하는지."""

    def commit(self, *args, cwd=None):
        return self.run_in(cwd or self.repo, "git", *args)

    def test_first_commit_without_head_checks_staged_files(self):
        self.assertIsNone(self.head())
        self.write("lib/bad.dart", ANALYZE_BAD)
        self.git("add", "-A")

        blocked = self.commit("commit", "-m", "bad")

        self.assertNotEqual(blocked.returncode, 0)
        self.assertIsNone(self.head(), "차단된 첫 커밋은 만들어지지 않아야 한다")

        self.git("rm", "-q", "--cached", "lib/bad.dart")
        passed = self.commit("commit", "-m", "good")

        self.assertEqual(passed.returncode, 0, passed.stderr)
        self.assertIsNotNone(self.head())

    def test_hook_environment_does_not_leak_into_checks(self):
        """Git은 훅에 GIT_INDEX_FILE 등을 넘긴다. 스냅샷 안의 도구는 그 값을 보면 안 된다."""
        result = self.commit("commit", "-m", "clean")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("새어 들어왔습니다", result.stderr)
        self.assertEqual(len(self.flutter_calls()), 2)

    def test_hook_runs_for_dash_C_dash_c_and_alias(self):
        self.git("commit", "-q", "-m", "base")
        self.git("config", "alias.ci", "commit")
        self.write("lib/bad.dart", ANALYZE_BAD)
        self.git("add", "-A")
        base = self.head()
        variants = {
            "git -C": (self.tmp, ["git", "-C", str(self.repo), "commit", "-m", "x"]),
            "git -c": (self.repo, ["git", "-c", "user.name=someone", "commit", "-m", "x"]),
            "alias": (self.repo, ["git", "ci", "-m", "x"]),
        }

        for name, (cwd, command) in variants.items():
            with self.subTest(name):
                result = self.run_in(cwd, *command)

                self.assertNotEqual(result.returncode, 0)
                self.assertIn("commit_gate: 차단", result.stderr)
                self.assertEqual(self.head(), base)

    def test_commit_dash_a_checks_the_content_being_committed(self):
        self.git("commit", "-q", "-m", "base")
        base = self.head()
        self.write("lib/ok.dart", ANALYZE_BAD)  # stage하지 않고 -a로 커밋

        result = self.commit("commit", "-am", "bad")

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.head(), base)

    def test_violation_only_in_linked_worktree_blocks_that_tree(self):
        self.git("commit", "-q", "-m", "base")
        linked = self.tmp / "linked tree"
        self.git("worktree", "add", "-q", "-b", "feature", str(linked))
        self.write_local_inputs(linked)
        self.write("lib/bad.dart", ANALYZE_BAD, linked)
        self.git("add", "-A", cwd=linked)
        self.write("lib/fine.dart", "void fine() {}\n")
        self.git("add", "-A")

        in_linked = self.commit("commit", "-m", "bad", cwd=linked)
        in_main = self.commit("commit", "-m", "fine")

        self.assertNotEqual(in_linked.returncode, 0)
        self.assertIn("commit_gate: 차단", in_linked.stderr)
        self.assertEqual(in_main.returncode, 0, in_main.stderr)

    def test_target_tree_without_gate_blocks_with_reason(self):
        self.git("commit", "-q", "-m", "base")
        base = self.head()
        self.git("rm", "-q", "tool/commit_gate.sh")

        result = self.commit("commit", "-m", "remove gate")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("이 작업 트리에 게이트가 없습니다", result.stderr)
        self.assertEqual(self.head(), base)


if __name__ == "__main__":
    unittest.main()
