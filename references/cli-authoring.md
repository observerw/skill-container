# CLI Authoring Patterns

Use this reference when implementing the skill CLI project (for example TypeScript + Commander or Python + Typer).

When to read this: read when designing command structure, safety behavior, dependencies, and help output.

## Core Principles (Adapted from Script Guidance)

These principles are the CLI equivalent of the old `scripts/` guidance.

1. Deterministic execution first.
2. Keep dependencies explicit and reproducible.
3. Make dangerous operations safe by default.
4. Keep commands modular and testable.
5. Make usage discoverable via `--help`.

## 1) Deterministic Execution

- Treat the CLI as production runtime code, not disposable glue.
- Pin runtime and dependency versions.
- Keep behavior stable across repeated runs.
- Keep command names and flags backward-compatible when possible.

## 2) Dependency Strategy

- Add dependencies that directly support CLI capabilities.
- Pin versions and commit lockfiles for reproducibility.
- Keep the language toolchain consistent between repository and Containerfile.
- Remove unused dependencies during normal maintenance.

Language-specific options:

- **Python + Typer**: uv is a convenient choice (`uv.lock`, `uv run`), but any consistent toolchain is acceptable.
- **TypeScript + Commander**: Bun is a convenient choice (`bun.lock`, `bun run`), but any consistent toolchain is acceptable.

Optional convenience install pattern:

If you choose Bun and/or uv, you can install them in `Containerfile` by copying binaries from official images:

```Dockerfile
COPY --from=oven/bun:latest /usr/local/bin/bun* /usr/local/bin/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
```

In SKILL.md, document runtime usage commands, not tool installation steps.

## 3) Safety for Mutating Commands

For commands that delete, overwrite, or modify data, implement a dry-run path.

Required behavior:

- Provide `--dry-run` to preview planned changes without writing.
- Print a clear summary of scope (which files/resources would change).
- Require explicit execution intent for real writes (for example `--apply` or `--yes`).
- Keep exit codes meaningful (`0` success, non-zero failure).

Agent workflow expectation:

1. Run `--dry-run` first.
2. Show intended changes.
3. Ask for confirmation before non-reversible operations.

## 4) Command Architecture

Prefer small subcommands with clear contracts.

- One subcommand = one primary responsibility.
- Keep orchestration in command handlers; put business logic in reusable modules.
- Avoid hidden global state.
- Keep I/O boundaries explicit (input paths, output paths, env vars).

## 5) Agent-Friendly CLI UX

Design output for both humans and agents.

- Support `--help` globally and per subcommand.
- Keep help text short, concrete, and example-driven.
- Offer machine-readable output mode (`--json`) for key commands when practical.
- Write errors to stderr and include actionable next steps.
- Keep stdout stable when it is consumed programmatically.

## Recommended Layouts

TypeScript + Commander:

```text
cli/
  package.json
  tsconfig.json
  src/
    main.ts
    commands/
      <command>.ts
    lib/
      <shared>.ts
```

Python + Typer:

```text
cli/
  pyproject.toml
  src/skill_cli/
    main.py
    commands/
      <command>.py
    lib/
      <shared>.py
```

## Minimal Quality Gates Before Release

- `--help` works at root and subcommand level.
- At least one representative command succeeds in container smoke test.
- Mutating commands implement and verify `--dry-run`.
- Error paths return non-zero and clear messages.
- Published image is updated and referenced in SKILL frontmatter `image`.

## SKILL.md Integration Pattern

In SKILL.md, keep CLI docs minimal:

- Show complete `docker run`/`podman run` examples with published image.
- Include this sentence: "Use `--help` (and `<subcommand> --help`) to get exact usage and parameters."
- Do not duplicate full option tables from CLI help.

This keeps SKILL.md concise while letting the CLI remain the source of truth for detailed parameters.
