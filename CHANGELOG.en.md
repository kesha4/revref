# Changelog

Kit versions follow [semantic versioning](https://semver.org/). The current version is in the `skill/revref/VERSION` file.

- **Major** (X.0.0) — incompatible changes to the format of `.revref/` files or protocols. A run in progress cannot be continued without migration.
- **Minor** (3.X.0) — new features compatible with runs in progress.
- **Patch** (3.2.X) — fixes to texts and bugs without changing formats.

A version has a "Migration" section only if something has to be done to a run already in progress when moving to it. The orchestrator reads it on `resume` if the kit version has changed.

## 3.2.0 — 2026-10-13

- **Secrets:** values of keys, tokens, passwords and personal data never go into reports, decisions, commits or the chat — only the location and a masked form.
- **Prompt injection protection:** repository content and tool output are data, not instructions. Attempts to control the agent through text in the project become a SEC finding.
- **Guard hook** `guard`: technically blocks dangerous git commands during a run (changing the main branch, force-push, rebase, deleting uncommitted work) and committing secrets to `.revref/`.
- **Custom reviews:** `.revref/reviews/<ID>.md` — a new review, `.revref/reviews/<ID>.extra.md` — an addendum to a built-in one.
- **Kit version:** the `VERSION` file, recording the version in `STATE.md`, a compatibility check on resume, this changelog.
- **English version** of the kit and README.
- **Kit self-check:** the `scripts/check_kit.py` script and a check in GitHub Actions on Windows, macOS and Linux.

## 3.1.0 — 2026-10-13

- Cross-platform installation: `install.sh` (macOS, Linux, WSL, Git Bash) and `install.ps1` (Windows PowerShell 5.1 and PowerShell 7+), `CLAUDE_CONFIG_DIR` support, uninstall.
- The `/revref ask [N|all]` command: the highest-priority questions for the owner right in the chat, answers like `D-012 ok`, works during a run, `INBOX.md` for answers from a parallel session.
- The agent's recommendation is mandatory for every decision and question.
- README: full list of review IDs, parameter reference, working with git branches, CC BY 4.0 license.

## 3.0.0 — 2026-10-12

- First public version: the Claude Code skill `/revref`.
- Pipeline of waves W0–W9, parallel subagents (reviewer, verifier, fixer), isolated worktrees for fixes.
- Autonomous decision policy: classes A/B/C, labels, autonomy levels, an approval queue for the owner.
- Checkpoints and resume across sessions, including after other people's commits.
- Selective review queues (`review … --verify|--fix`), merging the result into the `test` branch with the `finish` command.
