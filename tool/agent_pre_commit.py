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
# --shallow-file은 문서에 없지만 Git이 다음 토큰을 값으로 받는다.
GIT_OPTIONS_WITH_VALUE = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--attr-source", "--shallow-file",
}
# 짧은 옵션 묶음에서 이 글자 뒤는 옵션이 아니라 값이다.
COMMIT_SHORT_OPTIONS_WITH_VALUE = "mFCct"  # 붙여 쓰지 않으면 다음 토큰이 값(-m "msg")
COMMIT_SHORT_OPTIONS_WITH_ATTACHED_VALUE = "Su"  # 값은 붙여 쓸 때만(-S<keyid>)
# 구분자를 따옴표로 감싼 here-document: `<<'EOF'`, 시작 줄의 나머지(rest, 줄 이어쓰기까지), 본문(body), 끝 줄.
# 따옴표 없는 `<<EOF`의 본문은 셸이 `$(…)`를 실행하므로 늘 명령으로 본다. 구분자는 따옴표 바로 뒤에서
# 단어가 끝나야 한다(`<<'EOF'x`의 구분자는 EOFx). 끝 줄 앞뒤 공백을 허용하므로 셸보다 일찍 끝날 수는
# 있어도 늦게 끝나지는 않는다.
HEREDOC = re.compile(
    r"(?<!<)<<-?[ \t]*(['\"])([A-Za-z_]\w*)\1(?=[\s;&|<>()])(?P<rest>(?:[^\\\n]|\\.)*\n)(?P<body>.*?)^[ \t]*\2[ \t]*$",
    re.S | re.M,
)
# 본문이 커밋 메시지로만 쓰이는 here-document의 `<<` 앞부분. 줄(`\`로 이어 쓴 줄 포함) 맨 앞이나 그 줄에서
# 따옴표·`\` 밖의 `;`·`&`·`|` 뒤에서 시작하는 단순 명령이 변수 지정(값은 `[\w./:@%+,-]`)·경로만 앞에 둔
# git … commit …이고, `-m "$(cat `(m으로 끝나는 짧은 옵션 묶음, --message=, --message 포함)이나
# `-F -`(--file=-, --file - 포함)로 끝나야 한다. git 앞의 다른 단어(`eval`, `env` 등)는 본문을 다시 실행할 수 있으므로 메시지로 보지 않는다.
# 앞 줄이 `\`로 끝나면 그 줄 맨 앞은 명령의 시작이 아니다(`\\`⏎도 그렇게 보아 메시지로 보지 않을 뿐이다).
COMMIT_MESSAGE_HEREDOC_PREFIX = re.compile(
    r"^(?<!\\\n)(?:(?:[^'\"\\\n]|'[^'\n]*'|\"(?:[^\"\\\n]|\\.)*\"|\\.)*[;&|])?[ \t]*"
    r"(?:[A-Za-z_]\w*=[\w./:@%+,-]*[ \t]+)*(?:[\w./~-]*/)?git[ \t]"
    r"(?:[^;&|()\n]*[ \t])?commit[ \t](?:[^;&|()\n]*[ \t])?"
    r"(?:(?P<substitution>(?:-[A-Za-z]*m|--message=?)[ \t]*\"\$\(cat)|(?:-F|--file=?)[ \t]*-)[ \t]*$",
    re.M | re.S,
)


def block(reason):
    print(f"agent_pre_commit: 차단 — {reason}", file=sys.stderr)
    sys.exit(2)


def split_heredocs(command):
    """(커밋 메시지 here-document를 지운 명령, 그 밖의 here-document 본문 목록)을 돌려준다.

    본문이 커밋 메시지로만 쓰이면 데이터라 `<<'EOF'`부터 끝 줄까지 지우고, 그 줄의 나머지는 커밋 명령의
    인자로 남긴다. 그 나머지에 `|`·`<`·`>`가 있으면 본문이 다른 명령으로 갈 수 있어 메시지로 보지 않고,
    `-m "$(cat` 형태는 끝 줄 바로 다음 줄이 `)"`로 시작해야 한다(본문이 곧바로 메시지 인자가 된다).
    그 밖의 본문은 셸이 실행할 수 있으므로(`bash <<'EOF'`, `cat <<'EOF' | sh`) 제자리에 두어 명령으로 본다.
    """
    bodies = []

    def split(match):
        prefix = COMMIT_MESSAGE_HEREDOC_PREFIX.search(command, 0, match.start())
        is_message = (
            prefix
            and not re.search(r"[|<>]", match["rest"])
            and (not prefix["substitution"] or re.match(r"\n[ \t]*\)\"", command[match.end():]))
        )
        if is_message:
            return match["rest"]
        bodies.append(match["body"])
        return match[0]

    return HEREDOC.sub(split, command), bodies


def simple_commands(command):
    """셸 명령을 `&&`, `;`, `|` 등으로 나눈 단순 명령(토큰 목록)들을 돌려준다."""
    command, bodies = split_heredocs(command)
    # 홀수 개의 백슬래시 뒤 줄바꿈만 줄 이어쓰기라 명령을 나누지 않는다(`\\`는 백슬래시 문자다).
    # 나머지 줄바꿈은 `;`로 본다.
    command = re.sub(r"(?<!\\)((?:\\\\)*)\\\n", r"\1", command).replace("\n", " ; ")
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    current = []
    for token in lexer:
        if token and all(ch in "();<>|&" for ch in token):
            yield current
            current = []
        else:
            current.append(token)
    yield current
    # 제자리의 본문은 `sh -c "$(cat <<'EOF' …)"`처럼 따옴표 안이면 한 토큰이 되므로 따로 한 번 더 나눈다.
    for body in bodies:
        yield from simple_commands(body)


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

        args = iter(rest[1:])
        for arg in args:
            if arg == "--":
                break
            # Git은 긴 옵션의 고유한 앞부분도 받아들인다(--no-verif). --no-ver·--no-v는
            # --no-verbose와 겹쳐 Git이 거부하지만, 함께 막아도 해가 없어 규칙을 단순하게 둔다.
            if len(arg) >= len("--no-v") and "--no-verify".startswith(arg):
                bypass = "--no-verify 로 Git 훅을 건너뛸 수 없습니다."
            elif arg == "--message":
                next(args, None)
            # 붙여 쓴 값(-nm"fix bug", -nm"$(…)")에 공백·기호가 있어도 값을 받는 글자 앞까지는 옵션이다.
            elif re.match(r"-[A-Za-z]", arg):
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


def mentions_hooks_path(command):
    """셸이 지우는 따옴표·백슬래시·줄 이어쓰기를 뺀 명령에 core.hooksPath가 있는가.

    `core."hooksPath"`, `core.$"hooksPath"`, `core.hooks\\Path`도 셸을 거치면 core.hooksPath가 된다.
    토큰화에 실패한 명령에도 그대로 쓸 수 있도록 원문 문자열에서 지운다.
    """
    unquoted = re.sub(r"\\\n|\$(?=[\"'])|[\"'\\]", "", command)
    return "core.hookspath" in unquoted.lower()


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
        text = split_heredocs(command)[0]
        if not re.search(r"\bgit\b.*\bcommit\b", text, re.S):
            return
        bypass = None
        # 단어 안이 아닌 옵션만 본다: --no-verify와 그 약어, n이 든 짧은 옵션 묶음(-n, -an, -nm).
        # 앞 글자는 공백·따옴표만이 아니라 `\`·`{` 등 셸이 지우거나 펼치는 문자일 수도 있다.
        if re.search(r"(?<![\w-])--no-v(?:e(?:r(?:i(?:fy?)?)?)?)?(?![\w-])", text):
            bypass = "--no-verify 로 Git 훅을 건너뛸 수 없습니다."
        elif re.search(r"(?<![\w-])-(?!-)[A-Za-z]*n", text):
            bypass = "-n(--no-verify) 로 Git 훅을 건너뛸 수 없습니다."
        commits = [(cwd, bypass)]

    for target, bypass in commits:
        if not os.path.isdir(target):
            target = cwd
        if repository_id(target) != repository_id(PROJECT_ROOT):
            continue  # 다른 저장소의 커밋은 이 하네스의 관할이 아니다(연결된 worktree는 관할).
        if bypass:
            block(bypass)
        # `-c`, `--config-env`, GIT_CONFIG_*, 앞선 `git config`·export 등 경로가 많아,
        # 커밋과 같은 명령 어디에든 core.hooksPath가 있으면 우회로 본다.
        if mentions_hooks_path(command):
            block(
                "커밋 명령에 core.hooksPath를 넣어 Git 훅을 건너뛸 수 없습니다. 조회만 해도 막으므로 "
                "조회는 별도 명령으로, 커밋 메시지는 -F <파일>로 넘기세요."
            )
        check_hook_armed(target)


if __name__ == "__main__":
    main()
