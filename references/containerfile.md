# Containerfile Guidance

Use this reference when adding or reviewing `Containerfile` in a skill.

When to read this: read when the skill needs runnable tooling or containerized execution.

## When to Include (and Skip)

- Include a `Containerfile` when the skill needs runnable tooling or environment-specific dependencies.
- Skip `Containerfile` when the skill is primarily guidance/reference and does not require program-assisted execution.
- Prefer no `Containerfile` over a placeholder `Containerfile`.

## Goals

- Make execution reproducible across machines and runners.
- Keep images small, understandable, and quick to rebuild.
- Minimize security risk through least privilege and pinned inputs.
- Expose skill capabilities as a CLI-like interface callable with `docker run`/`podman run`.

## Design as an Agent-Facing CLI

Treat the container image as the runtime for a command-line app used by agent.

- Set a clear `ENTRYPOINT` to the skill command binary or dispatcher script.
- Keep subcommands and flags stable so invocations are predictable.
- Accept inputs via CLI args/stdin and emit machine-readable output (for example JSON) when possible.
- Document complete `docker run` examples using the published image reference, and rely on `--help` for detailed flag/parameter discovery.
- Mount host paths explicitly (`-v`) when reading/writing files.

Example invocation pattern:

```bash
docker run --rm -v "$PWD":/work -w /work my-skill-image <subcommand> [args]
```

If the container writes files to the mounted workspace, consider running with host UID/GID to avoid root-owned outputs:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/work -w /work my-skill-image <subcommand> [args]
```

## Distribution and Frontmatter `image`

For containerized skills, prefer distributing runtime via a published registry image (for example GHCR) rather than asking skill consumers to build locally.

- Publish the official image (for example `ghcr.io/<owner>/<repo>:<tag>`).
- Add `image` in SKILL.md frontmatter to point to that official image.
- Prefer pinned tags or immutable digests for reliability.
- In final SKILL usage docs, show `docker run`/`podman run` examples only; avoid local image build instructions.

## GitHub Actions Publishing Example

This repository includes a starter workflow at `.github/workflows/publish-image.yml` that publishes a GHCR image from `Containerfile`.

- Trigger: `workflow_dispatch` and tag push (`v*`).
- Auth: `secrets.GITHUB_TOKEN` with `packages: write` permission.
- Build/push: `docker/build-push-action`.
- Metadata: `docker/metadata-action` for tags and OCI labels.

Customize before reuse:

- Confirm `IMAGE_NAME` matches your target registry path.
- Tune tag strategy (semantic version tags, channel tags, SHA tags).
- Keep `SKILL.md` frontmatter `image` in sync with your released tag or digest.

For full repository publishing guidance (release flow, tags, and distribution conventions), see [github-publishing.md](github-publishing.md).

## SKILL.md CLI Documentation Pattern

Apply progressive disclosure in SKILL.md: document how to run the CLI, not the entire CLI reference.

- Start with this mandatory sentence in the CLI usage section:
  - "Use `--help` (and `<subcommand> --help`) to get exact usage and parameters."
- Show one canonical invocation template with full `docker run` options (mounts, workdir, env).
- Show a few high-value commands for common operations.
- Always include help discovery commands.
- Do not duplicate exhaustive subcommand/flag documentation that the CLI already exposes via `--help`.

Example pattern:

```bash
docker run --rm -v "$PWD":/work -w /work <published-image> --help
docker run --rm -v "$PWD":/work -w /work <published-image> <subcommand> --help
docker run --rm -v "$PWD":/work -w /work <published-image> <subcommand> [args]
```

Frontmatter example:

```yaml
---
name: my-skill
description: ...
image: ghcr.io/acme/my-skill-cli:1.2.0
---
```

## Recommended CLI Build Patterns

Prefer a real CLI project inside the skill directory, then package it into the image at build time.

For command architecture, safety semantics (`--dry-run`), and agent-facing UX conventions, see [cli-authoring.md](cli-authoring.md).

- TypeScript option: use `commander` (Bun is a convenient choice).
- Python option: use `typer` (uv is a convenient choice).
- If you choose Bun and/or uv, a convenient install pattern is copying binaries from official images:

```Dockerfile
COPY --from=oven/bun:latest /usr/local/bin/bun* /usr/local/bin/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
```
- Suggested layout:

```text
my-skill/
  Containerfile
  cli/
    ...project files...
```

TypeScript + Commander pattern:

```text
cli/
  package.json
  tsconfig.json
  src/main.ts
```

Python + Typer pattern:

```text
cli/
  pyproject.toml
  src/skill_cli/main.py
```

Container build pattern:

1. Copy the CLI project into a build stage.
2. Install/build dependencies.
3. Copy runtime artifacts (or installed package) into final stage.
4. Set `ENTRYPOINT` to the CLI executable/module.

Avoid embedding large ad-hoc shell scripts in `Containerfile` when the behavior belongs in CLI source code.

## Authoring Checklist

1. Choose a trusted base image and pin the version.
2. Implement CLI behavior as a TypeScript (`commander`) or Python (`typer`) project in the skill directory.
3. Install and pin dependencies required by CLI operations.
4. Add OCI-compliant image metadata via `LABEL` (at minimum include title, description, source, revision, licenses, created).
5. Use multi-stage builds when compilers or build tools are only needed at build time.
6. Keep layer order cache-friendly: stable dependencies first, frequently changing files later.
7. Set explicit `WORKDIR`.
8. Set explicit `ENTRYPOINT` and/or `CMD` so `docker run <image> ...` behaves like invoking a normal CLI app.
9. Prefer non-root user in final image.
10. Remove package manager caches and temporary build artifacts.
11. Publish image versions to a registry and keep frontmatter `image` in sync.
12. Keep consumer-facing docs focused on running the published image, not building it locally.

## OCI Metadata Labels

Prefer standard OCI annotation keys under `org.opencontainers.image.*`.

Common labels to include:

- `org.opencontainers.image.title`
- `org.opencontainers.image.description`
- `org.opencontainers.image.source`
- `org.opencontainers.image.url`
- `org.opencontainers.image.documentation`
- `org.opencontainers.image.version`
- `org.opencontainers.image.revision`
- `org.opencontainers.image.created`
- `org.opencontainers.image.licenses`

Example:

```Dockerfile
LABEL org.opencontainers.image.title="skill-runtime" \
      org.opencontainers.image.description="Runtime for skill-container workflows" \
      org.opencontainers.image.source="https://example.com/repo" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.licenses="MIT"
```

## Maintainer Validation Workflow

Use a simple, repeatable smoke test during development/CI before publishing image updates.

```bash
podman build -t my-skill-image -f Containerfile .
podman run --rm my-skill-image <smoke-command>
```

Prefer smoke commands that reflect real CLI usage (for example `--help` or a no-op validation subcommand).

If Podman is unavailable, use Docker with equivalent commands.

## Common Pitfalls

- Floating `latest` tags that change behavior unexpectedly.
- Copying entire repositories too early and invalidating caches.
- Running as root by default without a clear need.
- Missing runtime dependencies because only build stage was tested.
