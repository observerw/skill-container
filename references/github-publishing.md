# GitHub Repository Publishing Guide

Use this guide to publish a skill as a GitHub repository with a reproducible release flow.

When to read this: read when preparing a skill for public/team distribution and automated image releases.

## Why Publish as a Repository

- Keep source, runtime image definition, and release automation in one place.
- Enable transparent version history and pull-request based maintenance.
- Make image publishing and `.skill` packaging reproducible in CI.

## Recommended Repository Contents

At minimum, include:

- `SKILL.md`
- `Containerfile` (only when the skill needs runnable tooling)
- `references/`
- `assets/` (if needed)
- `.github/workflows/publish-image.yml`

Optionally include `.github/workflows/package-skill.yml` if you also automate `.skill` artifact builds.

## Release Flow (Recommended)

1. Merge validated changes to default branch.
2. Create a semantic version tag (for example `v1.2.0`).
3. Let GitHub Actions publish image tags to GHCR.
4. Record the released image tag/digest in `SKILL.md` frontmatter `image`.
5. If distributing `.skill` files, build/package from the same tagged commit.

## Registry and Permissions

- Publish to GHCR using `GITHUB_TOKEN` with `packages: write`.
- Keep image naming consistent (`ghcr.io/<owner>/<repo>` is a practical default).
- Prefer immutable digests for strict reproducibility when consumers pin runtime.

Common release blockers:

- Ensure workflow permissions include `contents: read` and `packages: write`.
- Ensure org/repo policy allows Actions to publish packages.
- Decide package visibility (`public` vs `private`) and document required auth for private pulls.

## Consumer-Facing Guidance

In `SKILL.md`, show runtime usage against published images only.

- Do not require consumers to build images locally.
- Keep CLI docs concise: runnable `docker run` examples plus `--help` discovery.

## Versioning Conventions

- Use semantic versions for release tags.
- Avoid floating tags as canonical references in docs.
- Treat `latest` as optional convenience, not as reproducible runtime.
