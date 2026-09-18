#!/usr/bin/env python3
"""에이전트(Claude Code·Codex) PreToolUse 훅 어댑터.

stdin으로 받은 도구 입력에서 셸 명령을 꺼내 `git commit` 실행 여부를 본다.
검사 자체는 실제 Git 훅(.githooks/pre-commit → tool/commit_gate.sh)이 커밋 대상
내용으로 수행한다. PreToolUse 시점에는 `git add ... && git commit`의 add가 아직
실행되지 않아 인덱스가 최종 상태가 아니므로, 여기서 게이트를 다시 돌리지 않고
(1) 그 Git 훅이 실행될 상태인지 (2) 훅 우회 옵션을 쓰는지만 확인한다.

종료 코드: 0 = 통과, 2 = 차단(사유는 stderr). 두 도구의 공통 규약이다.
별칭·래퍼를 거친 커밋은 감지하지 못한다. 그런 경로는 실제 Git 훅이 검사한다.
"""

import json
import os
import re
import shlex
import subprocess
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GIT_OPTIONS_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env"}
# 짧은 옵션 묶음에서 이 글자 뒤는 옵션이 아니라 값이다.
COMMIT_SHORT_OPTIONS_WITH_VALUE = "mFCct"  # 붙여 쓰지 않으면 다음 토큰이 값(-m "msg")
COMMIT_SHORT_OPTIONS_WITH_ATTACHED_VALUE = "Su"  # 값은 붙여 쓸 때만(-S<keyid>)


def block(reason):
    print(f"agent_pre_commit: 차단 — {reason}", file=sys.stderr)
    sys.exit(2)


def simple_commands(command):
    """셸 명령을 `&&`, `;`, `|` 등으로 나눈 단순 명령(토큰 목록)들을 돌려준다."""
    lexer = shlex.shlex(command.replace("\n", " ; "), posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    current = []
    for token in lexer:
        if token and all(ch in "();<>|&" for ch in token):
            yield current
            current = []
        else:
            current.append(token)
    yield current


def find_commits(command, cwd):
    """(커밋 대상 디렉터리, 우회 사유 또는 None) 목록을 돌려준다."""
    found = []
    directory = cwd
    for tokens in simple_commands(command):
        if len(tokens) >= 2 and tokens[0] == "cd":
            directory = os.path.join(directory, os.path.expanduser(tokens[1]))
            continue
        git_at = next((i for i, t in enumerate(tokens) if os.path.basename(t) == "git"), None)
        if git_at is None:
            continue

        target, bypass = directory, None
        rest = tokens[git_at + 1:]
        while rest and rest[0].startswith("-"):
            option = rest.pop(0)
            if option in GIT_OPTIONS_WITH_VALUE and rest:
                value = rest.pop(0)
                if option == "-C":
                    target = os.path.join(target, os.path.expanduser(value))
        if not rest or rest[0] != "commit":
            continue

        # `-c`, `--config-env`, GIT_CONFIG_KEY_n=… 어느 경로든 명령 안에서 훅 경로를 바꾸면 우회다.
        before_subcommand = tokens[: len(tokens) - len(rest)]
        if any("core.hookspath" in token.lower() for token in before_subcommand):
            bypass = "명령 안에서 core.hooksPath를 바꿔 Git 훅을 건너뛸 수 없습니다."

        args = iter(rest[1:])
        for arg in args:
            if arg == "--":
                break
            if arg == "--no-verify":
                bypass = "--no-verify 로 Git 훅을 건너뛸 수 없습니다."
            elif arg == "--message":
                next(args, None)
            elif re.fullmatch(r"-[A-Za-z]+", arg):
                for position, letter in enumerate(arg[1:], start=1):
                    if letter == "n":
                        bypass = "-n(--no-verify) 로 Git 훅을 건너뛸 수 없습니다."
                    if letter in COMMIT_SHORT_OPTIONS_WITH_ATTACHED_VALUE:
                        break
                    if letter in COMMIT_SHORT_OPTIONS_WITH_VALUE:
                        if position == len(arg) - 1:
                            next(args, None)
                        break
        found.append((target, bypass))
    return found


def git(directory, *args):
    result = subprocess.run(
        ["git", "-C", directory, *args], capture_output=True, text=True, check=False
    )
    return result.stdout.strip() if result.returncode == 0 else None


def repository_id(directory):
    common_dir = git(directory, "rev-parse", "--path-format=absolute", "--git-common-dir")
    return os.path.realpath(common_dir) if common_dir else None


def check_hook_armed(target):
    """커밋 대상 작업 트리에 실행 가능한 pre-commit 훅이 걸려 있어야 한다."""
    top = git(target, "rev-parse", "--show-toplevel")
    hooks_path = git(target, "config", "--get", "core.hooksPath")
    if not hooks_path:
        block(
            "core.hooksPath가 등록되지 않아 커밋 게이트가 실행되지 않습니다. "
            "프로젝트 루트에서 `git config --local core.hooksPath .githooks` 를 실행하세요."
        )
    # 상대 경로 hooksPath는 Git이 작업 트리 루트 기준으로 해석한다.
    hook = os.path.join(top, os.path.expanduser(hooks_path), "pre-commit")
    if not os.access(hook, os.X_OK):
        block(
            f"실행 가능한 pre-commit 훅이 없습니다: {hook} "
            "(하네스가 포함된 main을 병합했는지, 실행 권한이 있는지 확인하세요)"
        )
    with open(hook, encoding="utf-8", errors="replace") as file:
        if "tool/commit_gate.sh" not in file.read():
            block(
                f"pre-commit 훅이 tool/commit_gate.sh를 호출하지 않습니다: {hook} "
                "(다른 훅 디렉터리를 쓴다면 그 pre-commit에서 게이트를 호출하도록 병합하세요)"
            )


def main():
    try:
        payload = json.load(sys.stdin)
        command = payload["tool_input"]["command"]
        cwd = payload.get("cwd") or os.getcwd()
        if not isinstance(command, str):
            raise TypeError("tool_input.command가 문자열이 아닙니다")
    except (ValueError, KeyError, TypeError) as error:
        block(f"훅 입력을 해석하지 못했습니다: {error!r}")

    try:
        commits = find_commits(command, cwd)
    except ValueError:
        # 따옴표가 맞지 않아 토큰화에 실패한 명령은 문자열 검색으로 보수적으로 판단한다.
        if not re.search(r"\bgit\b.*\bcommit\b", command, re.S):
            return
        bypass = "--no-verify 로 Git 훅을 건너뛸 수 없습니다." if "--no-verify" in command else None
        commits = [(cwd, bypass)]

    for target, bypass in commits:
        if not os.path.isdir(target):
            target = cwd
        if repository_id(target) != repository_id(PROJECT_ROOT):
            continue  # 다른 저장소의 커밋은 이 하네스의 관할이 아니다(연결된 worktree는 관할).
        if bypass:
            block(bypass)
        check_hook_armed(target)


if __name__ == "__main__":
    main()
