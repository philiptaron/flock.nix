"""Dispatch the nixpkgs-review-gha `review` workflow with nixpkgs-review's own CLI.

Arguments are parsed by the real `nixpkgs-review pr` parser, then translated
into workflow_dispatch inputs for github.com/philiptaron/nixpkgs-review-gha.

By default each dispatched workflow run is watched until it completes, and
`--post-result` / `--approve-pr` / `--merge-pr` are performed locally once it
does. With the extra `--detach` flag (handled here, not by nixpkgs-review) the
runs are only dispatched and those actions are delegated to the workflow.
"""

import json
import os
import shlex
import subprocess
import sys
import time

from nixpkgs_review.cli import parse_args

REPO = os.environ.get("NIXPKGS_REVIEW_GHA_REPO", "philiptaron/nixpkgs-review-gha")
NIXPKGS = "NixOS/nixpkgs"

LINUX_SYSTEMS = ("x86_64-linux", "aarch64-linux", "riscv64-linux")
DARWIN_SYSTEMS = ("x86_64-darwin", "aarch64-darwin")


def warn(msg: str) -> None:
    print(f"nixpkgs-review-gha: warning: {msg}", file=sys.stderr)


def expand_numbers(numbers: list[str]) -> list[int]:
    result = []
    for token in numbers:
        first, sep, last = token.partition("-")
        if sep and first.isdigit() and last.isdigit():
            result.extend(range(int(first), int(last) + 1))
        elif token.isdigit():
            result.append(int(token))
        else:
            sys.exit(f"nixpkgs-review-gha: invalid PR number or range: {token!r}")
    return result


def system_inputs(args) -> dict[str, str]:
    tokens = (args.system or args.systems).split()
    if tokens == ["current"]:
        tokens = ["x86_64-linux", "aarch64-linux", "aarch64-darwin"]
    elif tokens == ["all"]:
        tokens = [*LINUX_SYSTEMS[:2], *DARWIN_SYSTEMS]
    inputs = {}
    for system in LINUX_SYSTEMS:
        inputs[system] = "true" if system in tokens else "false"
    for system in DARWIN_SYSTEMS:
        inputs[system] = "yes_sandbox_relaxed" if system in tokens else "no"
    if unknown := set(tokens) - {*LINUX_SYSTEMS, *DARWIN_SYSTEMS}:
        sys.exit(f"nixpkgs-review-gha: unsupported systems: {' '.join(sorted(unknown))}")
    return inputs


def extra_args(args) -> list[str]:
    extra = []
    if args.eval != "auto":
        extra += ["--eval", args.eval]
    if args.checkout != "merge":
        extra += ["--checkout", args.checkout]
    for flag, values in [
        ("--package", args.package),
        ("--additional-package", args.additional_package),
        ("--skip-package", args.skip_package),
        ("--allow", args.allow),
    ]:
        for value in values:
            extra += [flag, value]
    for flag, patterns in [
        ("--package-regex", args.package_regex),
        ("--skip-package-regex", args.skip_package_regex),
    ]:
        for pattern in patterns:
            extra += [flag, pattern.pattern]
    if args.build_args:
        extra += ["--build-args", args.build_args]
    if args.extra_nixpkgs_config != "{ }":
        extra += ["--extra-nixpkgs-config", args.extra_nixpkgs_config]
    if args.pkgs:
        extra += ["--pkgs", args.pkgs]
    if args.num_eval_workers != 1:
        extra += ["--num-eval-workers", str(args.num_eval_workers)]
    if args.max_memory_size != 4096:
        extra += ["--max-memory-size", str(args.max_memory_size)]
    for flag, is_set in [
        ("--no-headers", args.no_headers),
        ("--no-logs", args.no_logs),
    ]:
        if is_set:
            extra.append(flag)
    return extra


def warn_ignored(args) -> None:
    ignored = [
        ("--run", bool(args.run)),
        ("--no-shell", args.no_shell),
        ("--sandbox", args.sandbox),
        ("--print-result", args.print_result),
        ("--no-exit-status", args.no_exit_status),
        ("--no-pr-info", args.no_pr_info),
        ("--pr-json", bool(args.pr_json)),
        ("--remote", args.remote != "https://github.com/NixOS/nixpkgs"),
    ]
    for flag, is_set in ignored:
        if is_set:
            warn(f"{flag} has no effect when reviewing via GitHub Actions; ignoring")


def latest_run_id() -> int | None:
    out = subprocess.run(
        ["gh", "run", "list", "-R", REPO, "--workflow", "review.yml",
         "--limit", "1", "--json", "databaseId"],
        check=True, capture_output=True, text=True,
    ).stdout
    runs = json.loads(out)
    return runs[0]["databaseId"] if runs else None


def wait_for_new_run(previous: int | None) -> int:
    for _ in range(30):
        time.sleep(2)
        run_id = latest_run_id()
        if run_id is not None and run_id != previous:
            return run_id
    sys.exit("nixpkgs-review-gha: timed out waiting for the workflow run to appear")


def watch(run_id: int) -> bool:
    print(f"https://github.com/{REPO}/actions/runs/{run_id}", file=sys.stderr)
    ok = subprocess.run(
        ["gh", "run", "watch", str(run_id), "-R", REPO,
         "--exit-status", "--interval", "30"],
        stdout=subprocess.DEVNULL,
    ).returncode == 0
    subprocess.run(["gh", "run", "view", str(run_id), "-R", REPO])
    return ok


def fetch_report(run_id: int) -> str | None:
    out = subprocess.run(
        ["gh", "api", f"repos/{REPO}/actions/runs/{run_id}/artifacts",
         "--jq", '.artifacts[] | select(.name == "report.md") | .id'],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    if not out:
        warn(f"run {run_id} produced no report.md artifact")
        return None
    # The workflow uploads report.md unarchived, so the "zip" endpoint
    # serves the raw markdown.
    return subprocess.run(
        ["gh", "api", f"repos/{REPO}/actions/artifacts/{out}/zip"],
        check=True, capture_output=True, text=True,
    ).stdout


def run_local_actions(args, number: int, run_id: int, ok: bool) -> None:
    if args.post_result and (report := fetch_report(run_id)):
        subprocess.run(
            ["gh", "pr", "comment", str(number), "-R", NIXPKGS, "--body-file", "-"],
            check=True, input=report, text=True,
        )
    if ok and args.approve_pr:
        subprocess.run(
            ["gh", "pr", "review", str(number), "-R", NIXPKGS, "--approve"],
            check=True,
        )
    if ok and args.merge_pr:
        subprocess.run(["gh", "pr", "merge", str(number), "-R", NIXPKGS], check=True)


def main() -> None:
    argv = sys.argv[1:]
    detach = "--detach" in argv
    args = parse_args("nixpkgs-review", ["pr", *(a for a in argv if a != "--detach")])
    warn_ignored(args)

    inputs = system_inputs(args)
    inputs["post-result"] = "true" if detach and args.post_result else "false"
    if detach and args.merge_pr:
        inputs["on-success"] = "merge"
    elif detach and args.approve_pr:
        inputs["on-success"] = "approve"
    if extra := extra_args(args):
        inputs["extra-args"] = shlex.join(extra)

    runs = []
    for number in expand_numbers(args.number):
        cmd = ["gh", "workflow", "run", "review.yml", "-R", REPO, "-f", f"pr={number}"]
        for key, value in inputs.items():
            cmd += ["-f", f"{key}={value}"]
        previous = None if detach else latest_run_id()
        print(f"$ {shlex.join(cmd)}", file=sys.stderr)
        subprocess.run(cmd, check=True)
        if not detach:
            runs.append((number, wait_for_new_run(previous)))

    failed = False
    for number, run_id in runs:
        ok = watch(run_id)
        run_local_actions(args, number, run_id, ok)
        failed |= not ok
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
