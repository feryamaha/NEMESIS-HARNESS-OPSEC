#!/usr/bin/env python3
"""Executor local e verificavel para routing, workers, paralelismo e loop."""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any


SENSITIVE_MARKERS = ("~/opsec/scripts/", "/opsec/scripts/", "docker-compose.yml")


def section(text: str, name: str) -> str:
    pattern = rf"(?ims)^##\s+{re.escape(name)}\s*$\n(.*?)(?=^##\s+|\Z)"
    match = re.search(pattern, text)
    if not match:
        raise ValueError(f"secao ausente: {name}")
    value = match.group(1).strip()
    if not value:
        raise ValueError(f"secao vazia: {name}")
    return value


def route_for_spec(spec_path: Path) -> dict[str, Any]:
    text = spec_path.read_text(encoding="utf-8")
    category = section(text, "CATEGORY").splitlines()[0].strip().lower()
    files = section(text, "FILES INVOLVED")
    sensitive = any(marker in files for marker in SENSITIVE_MARKERS)

    if category == "docs":
        route, guard = "documentacao", "nenhum"
    elif category == "infra" and sensitive:
        route, guard = "reforcado"
    elif category == "bugfix":
        route, guard = "padrao", "preflight-f1"
    elif category == "feature" and sensitive:
        route, guard = "orquestrador", "reforcado"
    elif category == "feature":
        route, guard = "padrao", "nenhum"
    elif category == "refactor":
        route, guard = "padrao", "nenhum"
    else:
        raise ValueError(f"CATEGORY nao suportada: {category}")
    return {"category": category, "route": route, "guard": guard, "sensitive": sensitive}


def workers_for(route: dict[str, Any], complexity: str) -> list[str]:
    if route["route"] == "documentacao":
        return ["documentador"]
    workers = ["implementador", "revisor"]
    if route["sensitive"]:
        workers.append("preflight-checker")
    if complexity == "complexa":
        workers.append("documentador")
    return workers


def input_workers(text: str) -> list[str]:
    """Lê workers declarados na entrada, mantendo a decisão dependente do input."""
    try:
        workers_section = section(text, "WORKERS")
    except ValueError:
        return []
    workers = []
    for line in workers_section.splitlines():
        name = line.split(":", 1)[0].strip()
        if name:
            workers.append(name)
    return workers


def parse_job(value: str) -> tuple[str, list[str]]:
    if "=" not in value:
        raise ValueError("job deve ter formato nome=comando")
    name, command = value.split("=", 1)
    argv = shlex.split(command)
    if not name or not argv:
        raise ValueError("job sem nome ou comando")
    return name, argv


def run_job(name: str, argv: list[str]) -> dict[str, Any]:
    completed = subprocess.run(argv, capture_output=True, text=True, check=False)
    return {
        "name": name,
        "exit_code": completed.returncode,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
    }


def command_route(args: argparse.Namespace) -> int:
    print(json.dumps(route_for_spec(Path(args.spec)), ensure_ascii=False, sort_keys=True))
    return 0


def command_delegate(args: argparse.Namespace) -> int:
    spec_path = Path(args.spec)
    route = route_for_spec(spec_path)
    workers = input_workers(spec_path.read_text(encoding="utf-8")) or workers_for(route, args.complexity)
    payload = {"route": route, "workers": workers}
    if args.execute:
        if not args.job:
            raise ValueError("--execute exige ao menos um --job explicito")
        jobs = [parse_job(value) for value in args.job]
        results = [run_job(name, argv) for name, argv in jobs]
        payload["executed"] = results
        if any(result["exit_code"] != 0 for result in results):
            print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
            return 1
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return 0


def command_parallel(args: argparse.Namespace) -> int:
    jobs = [parse_job(value) for value in args.job]
    results: list[dict[str, Any]] = []
    with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
        futures = {pool.submit(run_job, name, argv): name for name, argv in jobs}
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda item: item["name"])
    print(json.dumps({"jobs": results}, ensure_ascii=False, sort_keys=True))
    return 0 if all(result["exit_code"] == 0 for result in results) else 1


def command_loop(args: argparse.Namespace) -> int:
    evaluator = shlex.split(args.evaluator)
    generator = shlex.split(args.generator) if args.generator else None
    previous: tuple[int, str, str] | None = None
    previous_score: float | None = None
    stagnant = 0
    ledger = Path(args.ledger) if args.ledger else None
    candidate = ""

    def run_generator(feedback: dict[str, Any] | None = None) -> subprocess.CompletedProcess[str]:
        if not generator:
            return subprocess.CompletedProcess([], 0, candidate, "")
        generator_env = dict(os.environ)
        generator_env.update({
            "EVALUATOR_EXIT_CODE": "" if feedback is None else str(feedback["exit_code"]),
            "EVALUATOR_STDOUT": "" if feedback is None else feedback["stdout"],
            "EVALUATOR_STDERR": "" if feedback is None else feedback["stderr"],
            "EVALUATOR_SCORE": "" if feedback is None or feedback["score"] is None else str(feedback["score"]),
        })
        return subprocess.run(generator, capture_output=True, text=True, check=False, env=generator_env)

    if generator:
        generated = run_generator()
        if generated.returncode != 0:
            print(f"generator-exit_code={generated.returncode}")
            return 1
        candidate = generated.stdout

    for cycle in range(1, args.max_cycles + 1):
        evaluator_env = dict(os.environ)
        evaluator_env["CANDIDATE_OUTPUT"] = candidate
        evaluated = subprocess.run(evaluator, capture_output=True, text=True, check=False, env=evaluator_env)
        result = (evaluated.returncode, evaluated.stdout, evaluated.stderr)
        score_match = re.search(r"(?m)^SCORE=([-+]?\d+(?:\.\d+)?)$", evaluated.stdout)
        score = float(score_match.group(1)) if score_match else None
        if previous is None:
            improved = True
        elif score is not None and previous_score is not None:
            improved = score > previous_score
        else:
            improved = result != previous
        stagnant = 0 if improved else stagnant + 1
        event = f"loop-ciclo={cycle} | exit_code={evaluated.returncode} | melhoria={'SIM' if improved else 'NAO'}"
        print(event)
        if ledger:
            with ledger.open("a", encoding="utf-8") as handle:
                handle.write(event + "\n")
        if args.feedback_file:
            Path(args.feedback_file).write_text(
                json.dumps({"cycle": cycle, "exit_code": evaluated.returncode,
                            "stdout": evaluated.stdout, "stderr": evaluated.stderr,
                            "score": score}, ensure_ascii=False),
                encoding="utf-8",
            )
        if evaluated.returncode == 0:
            return 0
        if stagnant >= args.max_stagnant:
            print("loop-parado=sem-melhoria")
            return 1
        if generator:
            generated = run_generator({"exit_code": evaluated.returncode, "stdout": evaluated.stdout,
                                       "stderr": evaluated.stderr, "score": score})
            if generated.returncode != 0:
                print(f"generator-exit_code={generated.returncode}")
                return 1
            candidate = generated.stdout
        previous = result
        previous_score = score
    print("loop-parado=max-ciclos")
    return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest="command", required=True)
    for name, handler in (("route", command_route), ("delegate", command_delegate)):
        sub = subcommands.add_parser(name)
        sub.add_argument("--spec", required=True)
        if name == "delegate":
            sub.add_argument("--complexity", choices=("simples", "complexa"), default="simples")
            sub.add_argument("--execute", action="store_true")
            sub.add_argument("--job", action="append", default=[])
        sub.set_defaults(handler=handler)
    parallel = subcommands.add_parser("parallel")
    parallel.add_argument("--job", action="append", required=True)
    parallel.set_defaults(handler=command_parallel)
    loop = subcommands.add_parser("loop")
    loop.add_argument("--evaluator", required=True)
    loop.add_argument("--generator")
    loop.add_argument("--ledger")
    loop.add_argument("--feedback-file")
    loop.add_argument("--max-cycles", type=int, default=5)
    loop.add_argument("--max-stagnant", type=int, default=5)
    loop.set_defaults(handler=command_loop)
    return parser


def main() -> int:
    try:
        args = build_parser().parse_args()
        return args.handler(args)
    except (OSError, ValueError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
