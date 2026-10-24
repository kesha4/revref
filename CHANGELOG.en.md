# Changelog

Kit versions follow [semantic versioning](https://semver.org/). The current version is in the `skill/revref/VERSION` file.

- **Major** (X.0.0) — incompatible changes to the format of `.revref/` files or protocols. A run in progress cannot be continued without migration.
- **Minor** (3.X.0) — new features compatible with runs in progress.
- **Patch** (3.2.X) — fixes to texts and bugs without changing formats.

A version has a "Migration" section only if something has to be done to a run already in progress when moving to it. The orchestrator reads it on `resume` if the kit version has changed.

## 3.7.0 — 2026-10-24

- **Token limit.** The run stops at a set share of the weekly subscription limit (95% by default): no new subagents, WIP commits and a full checkpoint, the window reset time in the message; after the reset, `resume`. A warning 10 points before the threshold; at 95% of the five-hour window, a checkpoint in advance. The budget question at `init` now includes the limit: "3 days, stop at 95% of the weekly limit".
- `hooks/usage.sh` — a status line command: saves the `rate_limits` that Claude Code passes only to the status line and prints them for the orchestrator (`--read`). The owner's previous status line is kept via `revref/statusline-next`. Connected at `init` with the owner's consent or manually (README → "Token limit").
- `CONFIG.md`: "Token limit"; `STATE.md`: checkpoint type "stopped: token limit"; `status` shows the limit. Test `scripts/test_usage.sh`.

### Migration

- If the `CONFIG.md` of a run in progress has no "Token limit" line, add "Token limit: 95% of the weekly limit (assumption)" and tell the owner. If `hooks/usage.sh --read` gives no data, offer to connect the status line; until consent, the limit is not tracked.

## 3.6.0 — 2026-10-14

- Review of changes: `review … --commits N`, `--commits <sha>,<sha>`, `--commits <from>..<to>`, `--since` / `--until` — any review is limited to the changes of the selected commits and what they affect.
- Findings get an "Origin: introduced / aggravated / pre-existing" field; reports `reports/<ID>.changes-<date>.md`, finding IDs `<ID>-c<NN>`.
- `review --commits N` without a review list — a comprehensive review of the changes (QR in changes mode), like a pull request review.

## 3.5.0 — 2026-10-13

- **Independent check of every fix.** Before merging (and before a pending patch is queued) the finished branch is checked by a verifier who was not the author of the review or the change, with three questions: is the premise right (specification, appendices, decisions taken, real process), what the change forbids or changes for an honest user, regression risk (other clients, an old client during an update, minimum platforms, server and containers — with tests and code reading). New prompt `prompts/work/verify-fix.md` and template `templates/fix-check.md`.
- The same three questions in the verification of findings.
- Label `LEGIT` (class C): a fix narrowing a legitimate scenario of an honest user — only by an owner decision. A "Legitimate scenarios" field in the finding format and "Affected legitimate scenarios" in decisions.
- `CONTEXT.md`: "Platforms, clients and environments" and "Sources of intended behavior" sections.
- Several subagents of one role on non-overlapping modules and files: a table in PROTOCOLS.md §3; verifiers of one report write verdicts into their own files — each file has one writer.

## 3.4.0 — 2026-10-13

- `/revref ask D-015`, `ask D-014 D-015`, `ask 3 D-015` — showing decisions by ID, including already answered ones (the answer can be changed until it is processed).
- Linked decisions ("together", "depends on", "blocks") are shown as one group of up to 3 cards; a group can be answered with one line `D-014+D-015 ok`. Contradictory answers within a "together" pair are not recorded without clarification.
- `DECISIONS.md` template: the "Linked decisions" field.

## 3.3.0 — 2026-10-13

Lessons from the first full run on the demo project (`examples/demo-shop`).

- `Monetary fixes per spec` setting: at the owner's choice, fixes labelled `MONEY` that are unambiguously prescribed by the specification and change no prices or rules can be class B (default — C).
- A task's class in the wave plan is the highest class among the labels of all its findings, including those added by verifiers.
- At every milestone pending branches are refreshed to the run branch and a trial merge of all of them together is checked: stale branches silently created duplicate classes and disabled tests on automatic merge.
- Without worktrees a fixer is launched only when no other subagent is writing to the working directory, and the step state is committed before it starts.
- Roles: mandatory cleanup of temporary files; the fixer does not revert uncommitted work while checking mutations.
- The TEST review checks whether test child processes inherit keys and secrets from the environment.
- `CONTEXT.md` template: the baseline is the state at the start of the run; the current state is in `STATE.md`.

## 3.2.1 — 2026-10-13

- The guard hook works even if git rewrote `guard.sh` with CRLF line endings (Windows with `core.autocrlf=true`, worktrees, fresh clones).
- `install.sh` sets the hook path in the agent files even when the install path contains spaces.
- CI: test for a CRLF copy of the hook; `actions/checkout@v5`.

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
