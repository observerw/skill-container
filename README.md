# Skill Container

Skill Containers are a simple, open, and portable format for giving agents new capabilities and expertise.

## Why?

> [!IMPORTANT]
> **TL;DR:** The original Agent Skills format still has several core engineering gaps: unclear runtime contracts, weak portability, limited safety boundaries, and no clean distribution/update story.

The original [Agent Skills](https://agentskills.io) format has good intentions, and its progressive disclosure idea is especially important for agent usability. In practice, however, it still has several design issues that make production use difficult.

- They use `scripts/` for executable tools, but **do not specify how to run them**:
  - Skills often use Python scripts with `#!/usr/bin/env python3` and third-party dependencies. This leads to:
    - Polluting your local environment (e.g. `pip install` into your system Python environment)
    - **No cross-platform support**
    - **No proper documentation** on how to run scripts
    - ...
  - Many skills are just wrappers around existing CLI programs, which often assume the right CLI (and version) is already installed on the host machine:
    - Easy to end up with the installed CLI version drifting from what the `SKILL` content expects
    - The same skill may behave differently across machines/environments
  - Safety boundaries are still very limited:
    - Everything runs with your full user privileges (filesystem, network, ssh agent, browser cookies, etc.): no sandbox, no permission model, no declared read/write/network contract. You can easily run a malicious script and mess up your system.
    - No integrity story (signing/checksums), no dependency pinning, and no standardized update flow -> supply-chain risks + no reliable security patching.
- There is **no clear way to distribute skills**:
  - Installation/update/uninstall workflows are not clearly standardized yet.
  - Claude Code has its own installation path (through `marketplace.json`), which is confusing, not open, and not portable.
  - There is a `.skill` format, but adoption is still very limited.
  - Vercel provides [skills.sh](skills.sh) as a workaround - helpful, but still not as standardized as npm or pip.

**This is not only a flexibility tradeoff; it also creates real operational friction.** The original design still misses several practices expected in mature software engineering.

## The Solution: Skill Container

How can we improve this? The solution is pretty simple: **OCI containers + GitHub distribution**.

### No More `scripts/`, Just Containerized CLI

When scripting is needed, each skill can be ported with a CLI program running in a docker environment (declared in a `Containerfile`):

```tree
├── .github/ (for distribution)
├── SKILL.md
├── references/
├── scripts/
│   └── cli.py (CLI entrypoint)
├── Containerfile (declares the runtime environment)
└── ... (other skill content, e.g. references, examples, etc.)
```

Container images solve the boring-but-critical engineering problems first:

- **Distribution is straightforward**: any GitHub repo can publish images to `ghcr.io`.
- **Updates are predictable**: just `docker pull`.
- **Runtime behavior is consistent** across all machines (Linux, Windows, Mac). The container is the contract: if it runs, it works.

On top of that, you get a sane safety baseline: runtime isolation from the host, plus explicit mount decisions so agents expose only what is needed instead of touching your whole machine.

**The container behaves as a real CLI**:

```bash
docker run --rm -v /local/file:/container/file ghcr.io/author/some-skill:latest --help
# This skill can help you with:
# - Doing X (usage: some-skill do-x --option value)
# - Doing Y (usage: some-skill do-y --option value)
# ...
```

one execution surface, better operability, and **progressive discovery via `--help`**. This is exactly the interface agent skills should have had from day one.

### Install Skill == Clone Repo from GitHub

Like `skills.sh`, **installation is just cloning a skill repo from GitHub**. The author publishes the CLI image to GHCR, and users clone the repo into their local skills directory.

Updates stay simple:

- **Pull code**: run `git pull` in the skill repo.
- **Pull runtime**: the runtime fetches the matching latest CLI image, so `SKILL.md` and executable behavior stay in sync instead of drifting apart.

## What's This Repository For?

This repository is itself **a skill for creating new skills or migrating existing ones into the Skill Container format**.

After you use this skill, the agent handles containerization details automatically (runtime packaging, container entry surface, and execution wiring), so skill authors can keep focusing on business/domain content as before.

Try it out!
