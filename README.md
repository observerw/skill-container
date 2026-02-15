# Skill Container

Skill Container are a simple, open and portable format for giving agents new capabilities and expertise.

## Why?

I have to say the original [Agent Skills](https://agentskills.io) format is really, _really_ lack of design.

Key problems:

- They use `scripts/` for executable tools, but **do not specify how to run them**:
  - Skills often use python scripts with `#!/usr/bin/env python3` with third-party dependencies, this leads to:
    - Messing up your local environment (e.g. `pip install` into your system python env)
    - No cross-platform support
    - Lack of proper documentation on how to run the scripts
    - ...
  - Zero safety consideration, I mean **zero**:
    - You can easily run a malicious script and mess up your system.
- There are **no way to distribute your skills**:
  - How to install/update/uninstall a skill properly? No one knows.
  - There is a claude-code specific ways to install skills (through `marketplace.json`), which is confusing and not portable at all.
  - There is a `.skill` format, but literally no one is using it.
  - Vercel provides [skills.sh](skills.sh) as a workaround,

**This is not flexibility, this is totally _mess_**. The original design have zero respect to the mature software-engineering practices.

## What's this repository for?
