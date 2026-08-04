"""Dispatch the nixpkgs-review-gha `review` workflow with nixpkgs-review's own CLI.

Arguments are parsed by the real `nixpkgs-review pr` parser, then translated
into workflow_dispatch inputs for github.com/philiptaron/nixpkgs-review-gha.
"""

import os
import shlex
import subprocess
import sys

from nixpkgs_review.cli import parse_args

REPO = os.environ.get("NIXPKGS_REVIEW_GHA_REPO", "philiptaron/nixpkgs-review-gha")

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


def main() -> None:
    args = parse_args("nixpkgs-review", ["pr", *sys.argv[1:]])
    warn_ignored(args)

    inputs = system_inputs(args)
    inputs["post-result"] = "true" if args.post_result else "false"
    if args.merge_pr:
        inputs["on-success"] = "merge"
    elif args.approve_pr:
        inputs["on-success"] = "approve"
    if extra := extra_args(args):
        inputs["extra-args"] = shlex.join(extra)

    for number in expand_numbers(args.number):
        cmd = ["gh", "workflow", "run", "review.yml", "-R", REPO, "-f", f"pr={number}"]
        for key, value in inputs.items():
            cmd += ["-f", f"{key}={value}"]
        print(f"$ {shlex.join(cmd)}", file=sys.stderr)
        subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
