"""tool/agent_pre_commit.py (Claude Code·Codex PreToolUse 어댑터) 검증."""

import json
import unittest

from harness_fixture import HarnessTestCase

HEREDOC_COMMIT = """git add -A && git commit -m "$(cat <<'EOF'
feat: something

Co-Authored-By: Someone <someone@example.invalid>
EOF
)\""""


class AgentPreCommitTest(HarnessTestCase):
    def setUp(self):
        super().setUp()
        self.git("commit", "-q", "-m", "base")
        self.flutter_log.unlink()

    def run_adapter(self, command, cwd=None, raw=None):
        payload = raw if raw is not None else json.dumps(
            {
                "hook_event_name": "PreToolUse",
                "tool_name": "Bash",
                "tool_input": {"command": command},
                "cwd": str(cwd or self.repo),
            }
        )
        # 저장소 사본의 어댑터를 실행하므로 "이 프로젝트"는 임시 저장소가 된다.
        return self.run_in(self.tmp, "python3", str(self.repo / "tool/agent_pre_commit.py"), input=payload)

    def assert_allowed(self, command, **kwargs):
        result = self.run_adapter(command, **kwargs)
        self.assertEqual(result.returncode, 0, f"{command!r}: {result.stderr}")

    def assert_blocked(self, command, reason, **kwargs):
        result = self.run_adapter(command, **kwargs)
        self.assertEqual(result.returncode, 2, f"{command!r}: {result.stderr}")
        self.assertIn(reason, result.stderr)

    def test_read_only_commands_pass_without_running_any_check(self):
        self.git("config", "--unset", "core.hooksPath")  # 커밋이었다면 차단될 상태
        for command in ["git log --oneline -5", "git status", "ls -la", 'grep -r "git commit" .']:
            with self.subTest(command):
                self.assert_allowed(command)
        self.assertEqual(self.flutter_calls(), [])

    def test_commit_passes_when_git_hook_is_armed(self):
        for command in ["git commit -m x", HEREDOC_COMMIT, f'git -C "{self.repo}" commit -m x']:
            with self.subTest(command):
                self.assert_allowed(command, cwd=self.tmp if " -C " in command else None)
        self.assertEqual(self.flutter_calls(), [], "검사는 Git 훅이 하므로 어댑터는 게이트를 돌리지 않는다")

    def test_commit_blocked_when_hooks_path_is_not_registered(self):
        self.git("config", "--unset", "core.hooksPath")

        for command in ["git commit -m x", HEREDOC_COMMIT, "cd lib && git commit -m x"]:
            with self.subTest(command):
                self.assert_blocked(command, "core.hooksPath")

    def test_commit_blocked_when_hook_is_not_executable(self):
        (self.repo / ".githooks/pre-commit").chmod(0o644)

        self.assert_blocked("git commit -m x", "실행 가능한 pre-commit 훅이 없습니다")

    def test_commit_blocked_when_hook_does_not_call_the_gate(self):
        hook = self.repo / ".githooks/pre-commit"
        hook.write_text("#!/bin/sh\nexit 0\n")
        hook.chmod(0o755)

        self.assert_blocked("git commit -m x", "tool/commit_gate.sh를 호출하지 않습니다")

    def test_hook_bypass_options_are_blocked(self):
        commands = [
            "git commit --no-verify -m x",
            "git commit -nm x",
            "git commit -an -m x",
            "git add -A && git commit -m x -n",
            "git commit -S -n -m x",
            "git -c core.hooksPath=/dev/null commit -m x",
            "VAR=/dev/null git --config-env=core.hooksPath=VAR commit -m x",
            "VAR=/dev/null git --config-env core.hookspath=VAR commit -m x",
            "GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m x",
        ]
        for command in commands:
            with self.subTest(command):
                self.assert_blocked(command, "수 없습니다")

    def test_option_like_text_inside_message_is_not_a_bypass(self):
        for command in ['git commit -m "docs: --no-verify 금지"', "git commit -mn", 'git commit -m "-n"  ']:
            with self.subTest(command):
                self.assert_allowed(command)

    def test_commit_in_another_repository_is_out_of_scope(self):
        other = self.make_repo("other")
        self.git("config", "--unset", "core.hooksPath", cwd=other)

        self.assert_allowed(f'git -C "{other}" commit --no-verify -m x')
        self.assert_allowed("git commit -m x", cwd=other)

    def test_cd_decides_which_repository_the_commit_targets(self):
        other = self.make_repo("other")

        self.assert_allowed(f'cd "{other}" && git commit --no-verify -m x')
        self.assert_blocked(f'cd "{self.repo}" && git commit --no-verify -m x', "수 없습니다", cwd=self.tmp)

    def test_linked_worktree_without_hook_is_blocked(self):
        self.git("rm", "-q", "-r", ".githooks")
        self.git("-c", "core.hooksPath=/dev/null", "commit", "-q", "-m", "drop hooks")
        linked = self.tmp / "linked"
        self.git("worktree", "add", "-q", "-b", "old", str(linked))

        self.assert_blocked("git commit -m x", "실행 가능한 pre-commit 훅이 없습니다", cwd=linked)

    def test_unparseable_hook_input_blocks(self):
        for raw in ["not json", "{}", json.dumps({"tool_input": {"command": ["git", "commit"]}})]:
            with self.subTest(raw):
                result = self.run_adapter(None, raw=raw)
                self.assertEqual(result.returncode, 2)
                self.assertIn("훅 입력을 해석하지 못했습니다", result.stderr)

    def test_unbalanced_quotes_fall_back_to_text_search(self):
        self.git("config", "--unset", "core.hooksPath")

        self.assert_blocked("git commit -m \"it's", "core.hooksPath")
        self.assert_allowed("echo \"it's")


if __name__ == "__main__":
    unittest.main()
