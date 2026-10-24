"""tool/agent_pre_commit.py (Claude Code·Codex PreToolUse 어댑터) 검증."""

import json
import unittest

from harness_fixture import HarnessTestCase

HEREDOC_COMMIT = """git add -A && git commit -m "$(cat <<'EOF'
feat: something

Co-Authored-By: Someone <someone@example.invalid>
EOF
)\""""
# 우회 옵션·`core` 같은 단어와 홀수 개의 큰따옴표가 든 커밋 메시지
MESSAGE = 'fix(core): drop -n and --no-verify\n\nSay "no to bypasses.\ngit commit --no-verify -n stays blocked.'


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
        for command in [
            "git log --oneline -5",
            "git status",
            "ls -la",
            'grep -r "git commit" .',
            "echo \\\\\\\ngit commit --no-verify -m x",  # \\ 뒤 \⏎는 줄 이어쓰기라 셸은 echo \git commit …을 실행한다
        ]:
            with self.subTest(command):
                self.assert_allowed(command)
        self.assertEqual(self.flutter_calls(), [])

    def test_commit_passes_when_git_hook_is_armed(self):
        for command in [
            "git commit -m x",
            HEREDOC_COMMIT,
            "git commit -F - <<EOF\nfix: plain body\nEOF",
            f'git -C "{self.repo}" commit -m x',
            "git commit --amend --no-edit",
        ]:
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
            # Git은 긴 옵션의 고유한 앞부분도 받아들인다.
            "git commit --no-verif -m x",
            "git commit -m x --no-veri",
            "git commit --no-v -m x",
            "git commit --no-verif -m $'it\\'s'",  # 토큰화 실패 → 문자열 검색
            "git commit --no-veri -m $'it\\'s'",
            "git commit --no-v -m $'it\\'s'",
            "git commit -n -m $'it\\'s'",
            "git commit -an -m $'it\\'s'",
            "git commit -nm $'it\\'s'",
            # 묶음에 붙여 쓴 값에 공백·$(…)가 있어도 값을 받는 글자 앞의 n은 -n이다.
            'git commit -nm"fix bug"',
            "git commit -nm'fix: x'",
            'git commit -anm"$(echo msg)"',
            "git commit -nm\"$(cat <<'EOF'\nmsg\nEOF\n)\"",
            "git commit \\--no-verify -m $'it\\'s'",  # 셸이 지우는 백슬래시
            "git commit \\-n -m $'it\\'s'",
            "git commit {--no-verify,} -m $'it\\'s'",  # 중괄호 확장
            "git commit -m x \\\n  --no-verify",  # 줄 이어쓰기는 한 명령이다
            "git commit -m x\\\\\\\n  --no-verify",  # \\ 뒤의 \ 도 줄 이어쓰기
            "echo done\\\\\ngit commit --no-verify -m x",  # \\ 는 백슬래시 문자라 줄바꿈이 명령을 나눈다
            # here-document 본문만 데이터다. 시작 줄의 이어쓰기와 끝 줄 뒤는 명령이다.
            "git commit -F - <<'EOF' && \\\n  git commit --no-verify -m y\nmsg\nEOF",
            "git commit -F - <<'EOF'\nends with \\\nEOF\ngit commit --no-verify -m y\ncat <<'EOF'\nx\nEOF",
            "cat <<<'EOF'\ngit commit --no-verify -m x\nEOF",  # here-string은 here-document가 아니다
            # 구분자는 셸 단어 전체다. 그 앞부분만 같은 줄에서 본문을 끝내지 않는다.
            "cat <<EOF-X\nhi\nEOF-X\ngit commit --no-verify -m x\nEOF",
            "cat <<EOF.txt\nhi\nEOF.txt\ngit commit --no-verify -m x\nEOF",
            "cat <<E\\OF\nhi\nEOF\ngit commit --no-verify -m x\nE",
            "cat <<'EOF'x\nhi\nEOFx\ngit commit --no-verify -m x\nEOF",
            "cat <<'EOF'.txt\nhi\nEOF.txt\ngit commit --no-verify -m x\nEOF",
            "cat <<'E'OF\nhi\nEOF\ngit commit --no-verify -m x\nE",
            # 따옴표 없는 구분자의 본문은 셸이 확장하므로 그 안의 $(…)가 실행된다.
            "cat <<EOF\n$(git commit --no-verify -m x)\nEOF",
            "git commit -F - <<EOF\nmsg $(git commit --no-verify -m y)\nEOF",
            # 값을 따로 받는 전역 옵션 뒤의 commit
            "git --attr-source HEAD commit --no-verify -m x",
            "git --shallow-file /dev/null commit --no-verify -m x",
            # 커밋 앞의 다른 명령에서 훅 경로를 바꾸는 경우
            "export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null; git commit -m x",
            "git config core.hooksPath /tmp/x && git commit -m x",
            "bash <<'EOF'\ngit config core.hooksPath /dev/null\nEOF\ngit commit -m x",  # here-document로 넘긴 스크립트
            "export GIT_CONFIG_PARAMETERS=\"'CORE.HOOKSPATH'='/dev/null'\"\ngit commit -m x",
            "export GIT_CONFIG_PARAMETERS=\"'core.hooksPath'='/dev/null'\"; git commit -m $'it\\'s'",
            # 셸이 따옴표·백슬래시를 지운 뒤 core.hooksPath가 되는 표기
            "git -c core.hooks\\Path=/dev/null commit -m x",
            'git -c core."hooksPath"=/dev/null commit -m x',
            'git -c core.$"hooksPath"=/dev/null commit -m x',
            "git -c core.$'hooksPath'=/dev/null commit -m x",
            "git -c 'core.hooks''Path=/dev/null' commit -m x",
            'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooks""Path GIT_CONFIG_VALUE_0=/dev/null git commit -m x',
            "VAR=/dev/null git --config-env=core.hooks\\Path=VAR commit -m x",
            "git -c core.hooks\\\nPath=/dev/null commit -m x",  # 줄 이어쓰기
            "export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooks\\Path GIT_CONFIG_VALUE_0=/dev/null; git commit -m x",
            "git -c core.hooks\\Path=/dev/null commit -m $'it\\'s'",  # 토큰화 실패 → 문자열 검색
        ]
        for command in commands:
            with self.subTest(command):
                self.assert_blocked(command, "수 없습니다")

    def test_option_like_text_inside_message_is_not_a_bypass(self):
        for command in [
            'git commit -m "docs: --no-verify 금지"',
            "git commit -mn",
            'git commit -m"no -n here"',  # 붙여 쓴 값
            'git commit -am"$(echo no -n)"',
            'git commit -m "-n"  ',
            "git commit -m $'it\\'s --no-verbose'",  # 토큰화 실패 → 문자열 검색
            "git commit -m $'it\\'s built-in'",  # 단어 안의 -n은 옵션이 아니다
        ]:
            with self.subTest(command):
                self.assert_allowed(command)

    def test_commit_message_heredoc_body_is_data_not_a_command(self):
        tab_indented = "\t" + MESSAGE.replace("\n", "\n\t")
        commands = [
            # 홀수 개의 큰따옴표가 든 본문
            HEREDOC_COMMIT.replace("feat: something", MESSAGE),
            *(f"git commit {option}\"$(cat <<'EOF'\n{MESSAGE}\nEOF\n)\"" for option in ["-am ", "--message=", "--message "]),
            *(f"git commit {option} <<'EOF'\n{MESSAGE}\nEOF" for option in ["-F -", "--file=-", "--file -"]),
            # git 앞에는 변수 지정·경로, 앞 명령과의 구분자(따옴표 밖, 줄 이어쓰기 포함)만 올 수 있다.
            f"A=1 B=x/y git commit -m \"$(cat <<'EOF'\n{MESSAGE}\nEOF\n)\"",
            f"/usr/bin/git commit -F - <<'EOF'\n{MESSAGE}\nEOF",
            f"git add \"a b.txt\" 'c;d.txt' && git commit -m \"$(cat <<'EOF'\n{MESSAGE}\nEOF\n)\"",
            f"git add -A \\\n  && git commit -m \"$(cat <<'EOF'\n{MESSAGE}\nEOF\n)\"",
            f"git status\ngit add -A; git commit -m \"$(cat <<'EOF'\n{MESSAGE}\nEOF\n)\"",
            f"git diff --cached --quiet || git commit -F - <<'EOF'\n{MESSAGE}\nEOF",
            # <<- 는 본문과 끝 줄 앞의 탭을 지운다.
            f"git commit -m \"$(cat <<-'EOF'\n{tab_indented}\n\tEOF\n\t)\"",
            f"git commit -F - <<-'EOF'\n{tab_indented}\n\tEOF",
            "git commit -F - <<'EOF'\nfix: explain why\n\ngit commit --no-verify and git commit -n stay blocked.\nEOF",
            "git commit -F - <<'EOF'\nfix: it's -n free\nEOF",
            "git commit -F - <<'EOF'\nEOF-style bodies mention git commit --no-verify\nEOF",  # 끝 줄은 줄 전체가 구분자
            "git commit -F - <<'EOF'\nfix: drop -n and --no-verify\nEOF\necho $'it\\'s'",  # 토큰화 실패 → 문자열 검색
        ]
        for command in commands:
            with self.subTest(command):
                self.assert_allowed(command)

    def test_heredoc_body_that_may_run_is_a_command(self):
        script = "\ngit commit --no-verify -m x\nEOF"
        commands = [
            # 셸에 넘긴 본문은 구분자를 따옴표로 감싸도 실행된다.
            "bash <<'EOF'" + script,
            "sh <<'EOF'" + script,
            "zsh <<'EOF'" + script,
            'bash -s <<"EOF"' + script,
            "cat <<'EOF' | bash" + script,
            "cat <<'EOF' > s.sh && bash s.sh" + script,
            "sh -c \"$(cat <<'EOF'" + script + "\n)\"",  # 따옴표 안의 본문도 명령이다
            # 메시지 형태라도 본문을 다른 곳으로 보내거나, -m이 다른 명령의 옵션이면 명령이다.
            "git commit -m \"$(cat <<'EOF' | bash" + script + "\n)\"",
            "git commit -m \"$(cat <<'EOF' > s.sh" + script + "\n)\" && bash s.sh",
            "git commit -m x && bash -cm \"$(cat <<'EOF'" + script + "\n)\"",
            # -m "$(cat 형태는 끝 줄 바로 다음 줄이 )" 일 때만 메시지다.
            "git commit -m \"$(cat <<'EOF'" + script + "\n| bash)\"",
            # git 앞에 다른 단어가 있으면 메시지가 아니다. eval은 메시지를 다시 명령으로 실행한다.
            "eval git commit -m \"$(cat <<'EOF'" + script + "\n)\"",
            "eval true\\; git commit -m \"$(cat <<'EOF'" + script + "\n)\"",  # 이스케이프한 ;는 구분자가 아니다
            "eval 'true; git commit ' -m \"$(cat <<'EOF'" + script + "\n)\"",  # 따옴표 안의 ;도 구분자가 아니다
            "X=a;eval git commit -m \"$(cat <<'EOF'" + script + "\n)\"",  # 변수 값은 ; 앞에서 끝난다
            "eval \\\ngit commit -m \"$(cat <<'EOF'" + script + "\n)\"",  # 줄 이어쓰기로 앞 줄에 붙은 git
            # 메시지 here-document 시작 줄의 나머지는 커밋 명령의 인자다.
            "git commit -m \"$(cat <<'EOF'\nmsg\nEOF\n)\" --no-verify",
            "git commit -F - <<'EOF' --no-verify\nmsg\nEOF",
        ]
        for command in commands:
            with self.subTest(command):
                self.assert_blocked(command, "--no-verify 로")

    def test_hooks_path_lookup_in_commit_command_is_blocked(self):
        self.assert_blocked("git config --get core.hooksPath && git commit -m x", "조회는 별도 명령으로")

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
