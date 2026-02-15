---
name: skill-container
description: Guide for creating effective skills with a Containerfile-first workflow. Use this when creating or updating a skill that benefits from reproducible containerized tooling instead of custom scripts.
license: LICENSE
---

# Containerized Skill Authoring

This skill shows how to author skills that ship a reproducible runtime via Containerfile + published image (typically GHCR), while keeping SKILL.md lean and executable.

## About Skills

Skills are small, self-contained packages that add domain workflows and resources. Treat SKILL.md as the agent runbook, and put deep details in `references/` plus runnable tooling in the published image.

### What Skills Provide

1. **Specialized workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for working with specific file formats or APIs
3. **Domain expertise** - Company-specific knowledge, schemas, business logic
4. **Bundled resources** - Containerfiles, references, and assets for complex and repetitive tasks

## Core Principles

### Concise is Key

Keep SKILL.md short. Assume the agent is competent and only document decisions, invariants, and workflow steps that are easy to miss. Prefer runnable examples over long explanations.

### Set Appropriate Degrees of Freedom

Match the level of specificity to the task's fragility and variability:

- **High freedom (text-based instructions)**: Use when multiple approaches are valid, decisions depend on context, or heuristics guide the approach.
- **Medium freedom (pseudocode or templates with parameters)**: Use when a preferred pattern exists, some variation is acceptable, or configuration affects behavior.
- **Low freedom (specific command sequence, few parameters)**: Use when operations are fragile and error-prone, consistency is critical, or a specific sequence must be followed.

Think of the agent as exploring a path: a narrow bridge with cliffs needs specific guardrails (low freedom), while an open field allows many routes (high freedom).

## Anatomy of a Skill

Every skill consists of a required SKILL.md file and optional bundled resources:

```
skill-name/
|-- SKILL.md (required)
|   |-- YAML frontmatter metadata (required)
|   |   |-- name: (required)
|   |   |-- description: (required)
|   |   `-- image: (recommended for containerized skills, e.g. ghcr.io/<owner>/<repo>:<tag>)
|   `-- Markdown instructions (required)
|-- Containerfile (optional) - Reproducible runtime for deterministic workflows
`-- Bundled Resources (optional)
    |-- references/       - Documentation intended to be loaded into context as needed
    `-- assets/           - Files used in output (templates, icons, fonts, etc.)
```

### SKILL.md (required)

Every SKILL.md consists of:

- **Frontmatter (YAML)**: Always include `name` and `description`. For containerized skills, also include `image` with the official published image reference (typically GHCR). `name` and `description` drive skill triggering; `image` provides runtime location.
- **Body (Markdown)**: Instructions and guidance for using the skill. Only loaded AFTER the skill triggers (if at all).

### Bundled Resources (optional)

#### Containerfile (`Containerfile`)

Use a `Containerfile` only when the skill needs program-assisted execution and deterministic reliability across environments. If the skill is primarily knowledge/process guidance and does not require runnable tooling, do not include a `Containerfile`.

Prefer a `Containerfile` over ad-hoc script authoring when reproducibility and dependency control matter.

Containerfile guidance:

1. Design the image as an agent-facing CLI runtime so agent can execute skill operations via `docker run`/`podman run` like a normal command-line tool.
2. Prefer implementing the CLI as a real project in the skill directory (for example TypeScript + Commander or Python + Typer), then package it into the image during build.
3. Start from a minimal, trusted base image and pin versions whenever possible.
4. Install and pin dependencies required by CLI operations.
5. Order layers from stable to volatile (system deps first, project files later) to improve cache reuse.
6. Use multi-stage builds to keep final image small and remove build-only dependencies.
7. Set explicit OCI metadata labels so image provenance and usage metadata are machine-readable.
8. Set explicit working directory, entrypoint/command, and environment defaults needed for skill tasks.
9. Run as non-root in the final stage unless root is strictly required.
10. Publish the image to a registry (for example GHCR) and set the published image reference in frontmatter `image`.
11. Keep build/smoke-test commands for maintainers (development/CI), and in final SKILL docs show runnable `docker run`/`podman run` commands plus `--help` discovery commands instead of exhaustive CLI parameter documentation.
12. Publish the skill as a GitHub repository so source, Containerfile, CI workflow, and released image are versioned together.

For a starter CI pipeline that publishes container images to GHCR, see `.github/workflows/publish-image.yml`.
For repository publishing guidance, see [references/github-publishing.md](references/github-publishing.md).
For CLI architecture and safety patterns, see [references/cli-authoring.md](references/cli-authoring.md).

For detailed examples and validation workflow, see [references/containerfile.md](references/containerfile.md).

#### References (`references/`)

Documentation and reference material intended to be loaded as needed into context to inform agent process and thinking.

- **When to include**: For documentation that agent should reference while working
- **Examples**: `references/finance.md` for financial schemas, `references/nda.md` for company NDA template, `references/policies.md` for company policies, `references/api_docs.md` for API specifications
- **Use cases**: Database schemas, API documentation, domain knowledge, company policies, detailed workflow guides
- **Benefits**: Keeps SKILL.md lean, loaded only when the agent determines it is needed
- **Best practice**: If files are large (>10k words), include grep search patterns in SKILL.md
- **Avoid duplication**: Information should live in either SKILL.md or references files, not both. Prefer references files for detailed information unless it is truly core to the skill-this keeps SKILL.md lean while making information discoverable without hogging the context window. Keep only essential procedural instructions and workflow guidance in SKILL.md; move detailed reference material, schemas, and examples to references files.

#### Assets (`assets/`)

Files not intended to be loaded into context, but instead used in the output the agent produces.

- **When to include**: When the skill needs files that will be used in the final output
- **Examples**: `assets/logo.png` for brand assets, `assets/slides.pptx` for PowerPoint templates, `assets/frontend-template/` for HTML/React boilerplate, `assets/font.ttf` for typography
- **Use cases**: Templates, images, icons, boilerplate code, fonts, sample documents that get copied or modified
- **Benefits**: Separates output resources from documentation, enables agent to use files without loading them into context

#### Keep Bundles Lean

Keep packaged skill content focused on execution. Avoid duplicating docs unless they directly improve agent behavior.

- In packaged skill bundles, avoid extra docs that duplicate SKILL.md or `references/`.
- In GitHub repositories, a short `README.md` is fine for humans, but SKILL.md remains the source of truth for agent behavior.

## Progressive Disclosure Design Principle

Skills use a three-level loading system to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by agent (Container images can carry complex toolchains without loading all implementation details into context)

### Progressive Disclosure Patterns

Keep SKILL.md as navigation plus a happy-path command flow.

- Keep SKILL.md under 500 lines when possible.
- Link reference files directly from SKILL.md (one hop, avoid deep nesting).
- Add "When to read this" at the top of each reference file.
- For long reference files, add a short TOC.
- Put variant-specific details in `references/`; keep SKILL.md focused on selection and execution.

## Skill Creation Process

Skill creation usually follows these steps:

1. Define triggers and constraints (`description` in frontmatter).
2. Implement runtime resources (`Containerfile` if needed, plus `references/` and `assets/`).
3. Write SKILL.md with runnable `docker run`/`podman run` examples and `--help` discovery commands.
4. Validate locally (build image + smoke test) when using `Containerfile`.
5. Package `.skill` only when your distribution channel requires it.
6. Iterate based on real usage.
7. Publish (GitHub repo + GHCR image tag/digest) and keep frontmatter `image` in sync.

Follow these steps in order, skipping only if there is a clear reason why they are not applicable.

### Step 1: Understanding the Skill with Concrete Examples

Identify 3-5 representative user requests and the expected outcomes.

Ask only the minimum questions needed to clarify:

- What should trigger the skill?
- What outputs are required?
- Which operations are common vs edge-case?

Finish this step when triggers and expected outcomes are unambiguous.

### Step 2: Planning the Reusable Skill Contents

For each representative request, decide which reusable resources are needed:

1. `Containerfile` (only if runnable tooling is required)
2. `references/` docs (schemas, policies, API notes)
3. `assets/` files (templates, sample inputs, static resources)

Quick heuristic:

- Repeated environment/tool setup -> add `Containerfile`
- Repeated factual lookup -> add `references/`
- Repeated file scaffolding -> add `assets/`

### Step 3: Initialize the Skill Workspace

Create a new skill directory with `SKILL.md` and only the resources you need.

- If you already have a template repository, copy it.
- Otherwise create a minimal structure manually (`SKILL.md`, optional `Containerfile`, optional `references/` and `assets/`).
- Prefer repository automation (CI workflows) over local scaffolding scripts.

### Step 4: Edit the Skill

When editing a skill, write for another agent instance. Include only non-obvious procedural details, domain constraints, and reusable assets that improve execution quality.

#### Learn Proven Design Patterns

Consult these helpful guides based on your skill's needs:

- **Multi-step processes**: See `references/workflows.md` for sequential workflows and conditional logic
- **Specific output formats or quality standards**: See `references/output-patterns.md` for template and example patterns
- **CLI implementation and safety**: See `references/cli-authoring.md` for command design, dependency strategy, and dry-run patterns
- **Repository release and distribution**: See `references/github-publishing.md` for publishing skills as GitHub repositories

These files contain established best practices for effective skill design.

#### Start with Reusable Skill Contents

To begin implementation, start with the reusable resources identified above: `Containerfile` (if needed), `references/`, and `assets/` files. Note that this step may require user input. For example, when implementing a `brand-guidelines` skill, the user may need to provide brand assets or templates to store in `assets/`, or documentation to store in `references/`.

For containerized execution, prefer creating a dedicated CLI project under the skill directory (for example `cli/`) using either TypeScript + Commander or Python + Typer. Keep command behavior in source code, then install/build that project in the `Containerfile` and expose it via `ENTRYPOINT`.

When adding or updating a `Containerfile`, validate it by actually building the image and running a minimal smoke test command in the container to confirm required tools and runtime behavior. If there are multiple variants, test a representative sample to balance confidence and time to completion. Then publish the validated image and reference it via frontmatter `image` so agents can run it directly.

Use CI to automate publish/release whenever possible (for example the GitHub Actions workflow in `.github/workflows/publish-image.yml`).

Delete any files not needed for the final skill.

#### Update SKILL.md

**Writing Guidelines:** Always use imperative/infinitive form.

##### Frontmatter

Write the YAML frontmatter with `name`, `description`, and `image` (for containerized skills):

- `name`: The skill name
- `description`: This is the primary triggering mechanism for your skill, and helps agent understand when to use the skill.
  - Include both what the skill does and specific triggers/contexts for when to use it.
  - Include all "when to use" information here-not in the body. The body is only loaded after triggering, so "When to Use This Skill" sections in the body are not helpful to the agent.
  - Example description for a `docx` skill: "Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extraction. Use when the agent needs to work with professional documents (.docx files) for: (1) Creating new documents, (2) Modifying or editing content, (3) Working with tracked changes, (4) Adding comments, or any other document tasks"
- `image`: For containerized skills, the official published image for runtime usage (prefer GHCR with pinned tag or digest).
  - Example: `ghcr.io/acme/skill-cli:1.2.0`
  - Example (immutable): `ghcr.io/acme/skill-cli@sha256:<digest>`

Avoid additional custom fields unless required by platform conventions.

##### Body

Write instructions for using the skill and its bundled resources.

For containerized skills, keep CLI usage docs focused and executable:

- Start the CLI usage section with this exact sentence:
  - "Use `--help` (and `<subcommand> --help`) to get exact usage and parameters."
- Show complete `docker run`/`podman run` commands with an explicit published image reference.
- Include discovery commands like `docker run ... --help` and `docker run ... <subcommand> --help`.
- Avoid duplicating full CLI argument/flag reference in SKILL.md; rely on CLI self-documentation for detailed options.
- Keep only a small set of high-value usage examples for common operations.

### Step 5: Package a `.skill` Artifact (Optional)

Only package `.skill` when your distribution channel requires it. Keep this as maintainer workflow, not consumer documentation.

When packaging is required, package from the same commit/tag used for image release. Use your repository's Python runner (for example `uv run` or `python`):

```bash
<python-runner> scripts/package_skill.py <path/to/skill-folder>
```

Optional output directory specification:

```bash
<python-runner> scripts/package_skill.py <path/to/skill-folder> ./dist
```

The packaging script will:

1. **Validate** the skill automatically, checking:
   - YAML frontmatter format and required fields
   - Skill naming conventions and directory structure
   - Description completeness and quality
   - File organization and resource references

2. **Package** the skill if validation passes, creating a `.skill` file named after the skill (for example, `my-skill.skill`) that includes all files and maintains the proper directory structure for distribution. The `.skill` file is a zip file with a `.skill` extension.

If validation fails, the script will report the errors and exit without creating a package. Fix any validation errors and run the packaging command again.

### Step 6: Iterate

After testing the skill, users may request improvements. Often this happens right after using the skill, with fresh context of how the skill performed.

**Iteration workflow:**

1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Identify how SKILL.md or bundled resources should be updated
4. Implement changes and test again

### Step 7: Publish as a GitHub Repository

For shareable, maintainable distribution, publish each skill as its own GitHub repository.

Recommended baseline:

1. Commit `SKILL.md`, `Containerfile` (if used), `references/`, `assets/`, and `.github/workflows/publish-image.yml`.
2. Enable GHCR publishing and confirm workflow permissions (`packages: write`).
3. Tag releases (for example `v1.0.0`) to publish immutable image versions.
4. Update `SKILL.md` frontmatter `image` to the official released image tag or digest.
5. Keep the repository source of truth synchronized with packaged `.skill` artifacts.
