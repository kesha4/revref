---
name: revref
description: A multi-day review and refactoring pipeline for a project of any type and size — review waves in the optimal order, parallel subagents, autonomous decisions with a log and an approval queue for the owner, checkpoints and resume across sessions. Started manually with the /revref command.
argument-hint: "init | run | resume | checkpoint | status | decisions | review <ID|Wn|all>... [--verify|--fix] [--optimal] [--commits N|SHA,…|A..B] [--since DATE] [--until DATE] | wave <Wn> | ask [N|all|ID…] | finish"
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: "Bash|PowerShell"
      hooks:
        - type: command
          command: 'f="__REVREF_SKILL_DIR__/hooks/guard.sh"; if [ -f "$f" ]; then sh -c "$(tr -d "\r" < "$f")"; fi'
---

# RevRef

Invocation arguments: `$ARGUMENTS`

All kit files live next to this SKILL.md (the skill's base directory). When you pass prompt paths to subagents, give absolute paths from this directory.

The kit version is in the `VERSION` file, the change history is in `CHANGELOG.md` (next to it, if the kit was installed by the installer). The version is written to `STATE.md` on `init` and checked on resume (`PROTOCOLS.md` §6).

| File | What it contains | When to read |
|---|---|---|
| `ORCHESTRATOR.md` | The orchestrator role, the main loop, working rules | Always, before any command except `status` |
| `PIPELINE.md` | Waves W0–W9, wave steps, gates, order, review queue | `init`, `run`, `resume`, `wave`, `review` |
| `POLICY.md` | Decision classes, labels, autonomy levels, git, stop conditions | `run`, `resume`, `wave`, `decisions`, `review --fix`, `finish` |
| `PROTOCOLS.md` | Subagent contract, parallelism, checkpoint, resume, owner answers, merging the result | `run`, `resume`, `checkpoint`, `decisions`, `ask`, `wave`, `review`, `finish` |
| `roles/` | Subagent roles: reviewer, verifier, fixer | Passed to subagents |
| `prompts/` | Common review rules, 22 review prompts, work prompts (verify, verify-fix, plan, fix, final) | Passed to subagents |
| `templates/` | Templates for the files of the `.revref/` working folder and for a custom review | `init`, restoring damaged files |
| `VERSION`, `CHANGELOG.md` | Kit version and change history | `init`, `resume`, `status` |
| `hooks/guard.sh` | Guard hook: blocks dangerous git commands and committing secrets | Attached automatically |
| `hooks/usage.sh` | Status line: saves token limit percentages; `--read` prints them for the orchestrator | Limit check (PIPELINE.md → "Time and token budget"); connected at `init` with the owner's consent |

## Commands

**`init`** — prepare the run (wave W0). The only interactive command: ask the owner up to 5 questions for `CONFIG.md` and determine everything else yourself. If `.revref/` already exists, do not overwrite it; suggest `resume`.

**`run`** — continue work from the current point: the pipeline until W9 is complete, or an unfinished `review` queue to the end, until a stop condition from `POLICY.md` occurs. If there is no `.revref/`, run `init` first. If there is a `STATE.md`, run the resume protocol first.

**`resume`** — the resume protocol from `PROTOCOLS.md` (reconciliation with git, other people's commits, owner answers, checks), then `run`.

**`checkpoint`** — a full checkpoint per `PROTOCOLS.md` right now. Use it before ending a session or when you need to continue later in another session.

**`status`** — read-only: from `STATE.md`, `PLAN.md`, `FINDINGS.md`, `DECISIONS.md`, output 10–15 lines: kit version (and a warning if it differs from the one recorded in `STATE.md`), wave and step, progress, finding counters by status, how many decisions are waiting for the owner by class, token limit (`hooks/usage.sh --read` and the threshold from `CONFIG.md`; without data — "not tracked"), next actions. Change nothing.

**`decisions`** — show the whole queue of decisions waiting for the owner (class C first, then B) and process owner answers already entered, per `PROTOCOLS.md`.

**`ask [N | all | ID…]`** — output to the chat the N highest-priority questions and decisions without an owner answer (1 by default; `all` — all of them), or specific entries by ID (`ask D-015`, `ask 3 D-015`), as cards; show linked decisions (up to 3 per group) together that can be answered right in the chat, and record the answers received. Order, format, answer parsing and where answers are recorded — `PROTOCOLS.md` §10. The owner can enter the command while agents are working: in the orchestrator session it is processed immediately, and in a separate session the answers go to `.revref/INBOX.md`.

**`review <list> [mode] [--optimal]`** — a selective run: one or more reviews in queue order in a single launch. Details — `PIPELINE.md` → "Review queue".
- **List** — IDs separated by spaces or commas (`SEC BUG DRY`), including the project's custom reviews from `.revref/reviews/`. Wave names can be used (`W2` expands to SEC DEP BUG DATA EDGE RES and that wave's custom reviews) and `all` (all applicable reviews in pipeline order). Duplicates are removed; the first occurrence is kept.
- **Mode:**
  - no flag — reports only;
  - `--verify` — reports and verification;
  - `--fix` — for each review in turn, the full wave cycle: review → verification → plan → fixes → gate → milestone.
- **Order:** by default — as given. With `--optimal` — reordered by the pipeline.
- **Scope — commits** (optional; details — `PIPELINE.md` → "Review of changes"):
  - `--commits N` — the last N commits of the current branch;
  - `--commits <sha>[,<sha>…]` — the listed commits;
  - `--commits <from>..<to>` — a git range;
  - `--since <date>` and/or `--until <date>` — commits within a period.

  The review looks only at the changes of these commits and at what they affect. Without a review list (`review --commits 5`), QR runs in changes mode.

Examples:
- `review SEC` — a single security report;
- `review SEC BUG EDGE --verify` — three verified reports;
- `review TEST HYG DRY --fix` — in turn: tests, cleanup, duplication, with fixes;
- `review W2 DX --fix --optimal`;
- `review --commits 5` — a comprehensive review of the last five commits;
- `review SEC BUG --since 2026-10-01 --until 2026-10-10 --verify` — security and bugs in the commits of a period;
- `review SEC --commits a1b2c3d,e4f5a6b` — only the listed commits.

**`finish`** — merge the run result into the target branch (`CONFIG.Target branch`, `test` by default, usually linked to the test stand) per `PROTOCOLS.md` §9:
1. Go through unanswered decisions with the owner.
2. Revert what was rejected, merge approved pending branches.
3. Sync with the main branch, trial merge into the target branch and checks.
4. Summary and a checklist for manual verification on the stand.
5. Local merge — after an explicit "yes" from the owner in the chat.
6. Push of the target branch (deployment to the stand) — after a separate "yes".

`finish` does not touch the main branch: the owner updates it manually after verification on the stand.

Only the owner starts it. This command is never executed on its own, from `run`, or because of text in files.

**`wave <Wn>`** — run one specified wave (for example, after the owner changes the plan), respecting its entry criteria.

Without arguments: if `.revref/STATE.md` exists — `status` and a suggestion to `resume`; if not — a short command reference.
