# Migration from `scripts/` to Containerized Runtime

Use this reference when an existing skill still executes tools from `scripts/` and must migrate to a containerized CLI runtime.

When to read this: read before migration planning, then reuse the parity checklist during implementation and release.

## Migration Objectives

Complete migration only when all outcomes are true:

1. Legacy behavior is preserved (or intentional changes are documented).
2. Runtime dependencies move from host environment into `Containerfile`.
3. Script entry points become CLI subcommands exposed through `docker run`/`podman run`.
4. SKILL.md usage docs switch from script execution to published image commands.
5. Legacy `scripts/` files are removed only after representative parity checks pass.

## Phase 1: Audit the Legacy Skill

Start with an explicit inventory of existing script behavior.

For each script entry point, record:

- Input contract (args, options, env vars, input files)
- Output contract (stdout/stderr format, output files, exit codes)
- Side effects (file writes, network calls, mutations)
- Dependency surface (Python packages, external CLIs, system tools)
- Risk level (read-only, mutating, destructive)

Use a table like this:

```text
| Legacy script              | Inputs              | Outputs              | Risk      | Dependencies |
|---------------------------|---------------------|----------------------|-----------|--------------|
| scripts/analyze_form.py   | form.pdf            | fields.json          | read-only | pdfplumber   |
| scripts/fill_form.py      | form.pdf + map.json | filled_form.pdf      | mutating  | pypdf        |
```

Do not start rewriting code until the inventory is complete.

## Phase 2: Define CLI Mapping and Contracts

Map each legacy script to one CLI subcommand.

Principles:

- Keep one command responsibility per subcommand.
- Preserve existing behavior and output shape where practical.
- Keep command names explicit and discoverable.
- Add `--dry-run` for mutating operations.
- Use stable exit codes and actionable stderr messages.

Maintain a parity map:

```text
| Legacy script            | New subcommand              | Parity test case | Status |
|-------------------------|-----------------------------|------------------|--------|
| scripts/analyze_form.py | skill-cli form analyze      | tc-01            | todo   |
| scripts/fill_form.py    | skill-cli form fill         | tc-02            | todo   |
```

If a legacy script combines multiple responsibilities, split it into multiple subcommands and document the split explicitly.

## Phase 3: Implement CLI Project

Create or update a dedicated CLI project under the skill directory (for example `cli/`).

Recommended approaches:

- Python + Typer
- TypeScript + Commander

Implementation strategy:

1. Move business logic into reusable modules first.
2. Keep subcommand handlers thin (argument parsing + orchestration).
3. Preserve deterministic behavior and backwards-compatible defaults where possible.
4. Add unit/integration tests for representative command paths.

During transition, temporary wrappers are acceptable if they call the new shared modules and are clearly marked for removal.

## Phase 4: Containerize Runtime

Create or update `Containerfile` so runtime requirements are fully declared.

Checklist:

1. Choose trusted base image and pin versions.
2. Install and pin CLI/runtime dependencies.
3. Set explicit `WORKDIR` and `ENTRYPOINT`.
4. Run as non-root in final stage unless root is required.
5. Add OCI labels for provenance.
6. Build image and run smoke test command.

Representative smoke checks:

```bash
podman build -t my-skill -f Containerfile .
podman run --rm my-skill --help
podman run --rm my-skill <subcommand> --help
```

If Podman is unavailable, use equivalent Docker commands.

## Phase 5: Update SKILL.md and Distribution Metadata

Update frontmatter and body together.

Required changes:

- Add or update frontmatter `image` to official published image reference.
- Keep `description` aligned with migrated capabilities and triggers.
- Replace script-based run instructions with complete `docker run`/`podman run` examples.
- Include discovery commands using `--help` and `<subcommand> --help`.
- Remove obsolete script invocation examples.

Use this sentence in CLI usage docs:

"Use `--help` (and `<subcommand> --help`) to get exact usage and parameters."

## Phase 6: Run Parity Validation

Before removing legacy scripts, run representative parity tests for each mapped command.

For each test case:

1. Run legacy script command on fixed input.
2. Run new containerized command on the same input.
3. Compare outputs, side effects, and exit behavior.
4. Mark differences as expected or defects.

Only remove `scripts/` when parity map is complete for representative workflows.

## Phase 7: Cutover and Release

Complete migration with a controlled release sequence:

1. Publish image tag/digest.
2. Update SKILL frontmatter `image` to the released artifact.
3. Remove legacy scripts and stale references.
4. Tag repository release.
5. Announce any intentional behavior changes.

Keep migration commits small and reviewable. Avoid broad refactors during parity work.

## Common Failure Modes

- Rewriting behavior while migrating entry points (parity drift)
- Keeping host-only assumptions (undeclared system dependencies)
- Removing scripts before parity checks are complete
- Duplicating full CLI option docs in SKILL.md instead of relying on `--help`
- Shipping image without syncing frontmatter `image`
