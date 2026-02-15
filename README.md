# Skill Container

Skill Containers are a simple, open, and portable format for giving agents new capabilities and expertise.

## Why?

> [!IMPORTANT]
> **TL;DR:** The original Agent Skills format looks flexible, but it breaks core engineering basics: unclear runtime contracts, weak portability, basically zero safety boundaries, and no clean distribution/update story.

I have to say the original [Agent Skills](https://agentskills.io) format is really, _really_ poorly designed. It feels like it was put together in 5 minutes and still presented as a serious "standard".

- They use `scripts/` for executable tools, but **do not specify how to run them**:
  - Skills often use Python scripts with `#!/usr/bin/env python3` and third-party dependencies. This leads to:
    - Messing up your local environment (e.g. `pip install` into your system Python environment)
    - **No cross-platform support**
    - **No proper documentation** on how to run scripts
    - ...
  - Many skills are just wrappers around existing CLI programs, which often assume the right CLI (and version) is already installed on the host machine:
    - Easy to end up with the installed CLI version drifting from what the `SKILL` content expects
    - The same skill may behave differently across machines/environments
  - Zero safety consideration, I mean **zero**:
    - Everything runs with your full user privileges (filesystem, network, ssh agent, browser cookies, etc.): no sandbox, no permission model, no declared read/write/network contract. You can easily run a malicious script and mess up your system.
    - No integrity story (signing/checksums), no dependency pinning, and no standardized update flow -> supply-chain risks + no reliable security patching.
- There is **no clear way to distribute skills**:
  - How do you install/update/uninstall a skill properly? No one knows.
  - Claude Code has its own installation path (through `marketplace.json`), which is confusing, not open, and not portable.
  - There is a `.skill` format, but literally no one uses it.
  - Vercel provides [skills.sh](skills.sh) as a workaround - decent, but still nowhere near npm or pip.

**This is not flexibility; this is a total _mess_.** The original design shows zero respect for mature software engineering practices.

## The Solution: Skill Container

How do we fix the mess? The solution is pretty simple: **OCI containers + GitHub distribution**.

### No More `scripts/`, Just Containerized CLI

When scripting is needed, each skill can be ported with a CLI program running in a docker environment (declared in a `Containerfile`):

```tree
├── Containerfile
├── SKILL.md
├── cli.py (entry point of the CLI)
├── pyproject.toml (third-party dependencies, in a standard format)
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
