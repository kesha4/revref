# RevRef v3 — infrastructure for multi-day review and refactoring

[Русский](README.md) · **English**

**RevRef** = **Rev**iew + **Ref**actoring.

RevRef v3 is a pipeline that runs every kind of review and refactoring of a project one after another in the optimal order, over several days, with parallel subagents and autonomous decisions. Every decision is recorded; decisions with serious consequences are placed in the approval queue for the owner. The state can be saved and the work resumed in any other session, even after other people's commits.

## How it works

```text
W0 Preparation ─ branch, .revref/, project map, check baseline
W1 Reconnaissance ── quick review QR → which reviews are needed, distribution of findings
W2 Security and correctness ── SEC DEP BUG DATA EDGE RES
W3 Foundation ── TEST DX (safety net before refactoring)
W4 Cleanup ──── HYG
W5 Structure ── ARC → DEC → DRY
W6 Operations ─ PERF OBS API I18N
W7 Interface ── RWD A11Y (can run in parallel with W4–W6)
W8 Documentation ─ CMT SPEC UDOC
W9 Final ────── QR delta, comparison with the baseline, final report

Each wave:
  reviews (parallel) → verification (fresh agents) → plan (groups with no file overlap)
  → fixes (parallel in isolated worktrees) → gate (checks) → milestone and checkpoint
```

**Roles.**
- **Orchestrator** — the main session: plans, merges, makes decisions, maintains the state files.
- **Reviewer, verifier, fixer** — subagents. The reviewer and verifier do not change code. The fixer works in a separate worktree and task branch, and only the orchestrator merges its work, after checks.

**Decisions.**
- 🟢 **A** — technical: made immediately.
- 🟠 **B** — change behavior, UX or contracts, or are debatable: made in a separate commit and placed in the queue.
- 🔴 **C** — money, data, access, legal matters: not merged without the owner; prepared in the branch `revref/pending/D-NNN`.

The full table of labels is in `skill-en/revref/POLICY.md`. Review IDs are explained in the section "Reviews: full list", branches and commits in the section "Working with git branches".

## Reviews: full list

22 reviews. The ID is used in commands (`/revref review SEC`), in report names (`.revref/reports/SEC.md`) and as the finding prefix (`SEC-01`). The prompts are in `skill-en/revref/prompts/reviews/<ID>.md`.

| ID | Review | Wave | What it checks |
|---|---|---|---|
| `QR` | Quick comprehensive review | W1, W9 | The overall picture across 9 blocks and the applicability of the other reviews; in W9 — the delta and refactoring regressions |
| `SEC` | Security | W2 | Threat model, authentication and authorization, injections, web vulnerabilities, cryptography, secrets |
| `DEP` | Dependencies and supply chain | W2 | Vulnerable, outdated, abandoned and unnecessary packages, lock files, licenses |
| `BUG` | Bugs and logic errors | W2 | Existing defects: conditions, null, asynchrony, resource leaks, dates, arithmetic |
| `DATA` | Data, databases and migrations | W2 | Schema and integrity constraints, indexes, transactions, migration safety, backups |
| `EDGE` | Edge cases | W2 | Empty and boundary values, Unicode, retries and concurrent requests, external system failures, validation at boundaries |
| `RES` | Resilience | W2 | Error handling, timeouts, retries, cascading failures, graceful shutdown, idempotency |
| `TEST` | Tests | W3 | Coverage of critical paths, test quality and stability, proposals for new tests |
| `DX` | Build, CI/CD and developer experience | W3 | Onboarding, build reproducibility, linters, CI, configuration and secrets, deployment and rollback |
| `HYG` | Code hygiene | W4 | Dead code, unused imports and dependencies, debug output, stale TODOs, permanent flags |
| `ARC` | Architecture | W5 | Module map, boundaries and coupling, layers and cycles, isolation of external systems, consistency of approaches |
| `DEC` | Decomposition | W5 | Overloaded files and functions, nesting, "god" objects, a plan for safe splitting |
| `DRY` | DRY | W5 | Duplicated logic, types and rules across layers, diverged copies — without merging coincidental similarity |
| `PERF` | Performance | W6 | Complexity on hot paths, N+1 and indexes, I/O, memory, frontend bundle — with a measurement method |
| `OBS` | Observability | W6 | Logs, tracing, metrics, health checks, alerts, audit log |
| `API` | API contracts | W6 | Consistency, semantics, backward compatibility, contract schemas, limits |
| `I18N` | Internationalization | W6 | Hardcoded strings, pluralization, date and currency formats, translation completeness, RTL |
| `RWD` | Responsive UI | W7 | Layout from 320 to 2560+ px, touch devices, 200% zoom, long content |
| `A11Y` | Accessibility (a11y) | W7 | WCAG 2.2 AA: keyboard, semantics, forms, contrast, screen readers |
| `CMT` | Code comments | W8 | Stale comments and comments contradicting the code, unnecessary and missing ones, public API descriptions |
| `SPEC` | Compliance with the specification and technical docs | W8 | Requirements traceability matrix, discrepancies between code and documents, whether README instructions work |
| `UDOC` | User documentation | W8 | Completeness, currency, clarity, tables and illustrations, testing against typical user tasks |

Wave names can be used in commands as groups: `/revref review W2` = SEC DEP BUG DATA EDGE RES.

## Custom reviews

Besides the 22 built-in reviews, a project can have its own: domain specifics, regulatory requirements, internal standards.

| File in the project | What it is |
|---|---|
| `.revref/reviews/<ID>.md` | A new review. Template — `skill-en/revref/templates/custom-review.md` |
| `.revref/reviews/<ID>.extra.md` | An addendum to a built-in review, without replacing it. For example, `SEC.extra.md` with VPN protocol specifics |

- **ID** — 2–8 uppercase Latin letters or digits, not matching a built-in one. It is also the finding prefix.
- **Wave** is set in `CONFIG.md`: `- Custom reviews: VPN → W2, GDPR → W8`. If it is not set, the agent assigns a wave based on the review's topic and explains the choice in `PLAN.md`.
- **Participation in the work.** Custom reviews go through the same steps, verification and decision policy, are included in `all` and in wave names, and can be run on their own: `/revref review VPN --fix`.

## Installation (Claude Code)

The kit works on Windows, macOS and Linux. The prompts and protocols themselves are platform-independent, and there are two equivalent installation scripts. The English version is installed with the `--lang en` / `-Lang en` flag; without the flag, the Russian version is installed (the default).

```bash
git clone https://github.com/kesha4/revref.git && cd revref
```

**macOS, Linux, WSL, Git Bash:**

```bash
./install.sh --lang en
```

**Windows PowerShell 5.1 or PowerShell 7+ on any OS:**

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Lang en
```

| Action | `install.sh` | `install.ps1` |
|---|---|---|
| Globally, for all projects | `./install.sh --lang en` | `./install.ps1 -Lang en` |
| Into a single project only (`<project>/.claude`) | `./install.sh --lang en --project <path>` | `./install.ps1 -Lang en -Project <path>` |
| Uninstall | `./install.sh --uninstall` | `./install.ps1 -Uninstall` |
| Russian version of the kit (default) | `./install.sh` | `./install.ps1` |

- **Where it goes.** The skill (with the guard hook) is copied to `<config folder>/skills/revref`, the agents to `<config folder>/agents/`. The installer writes the absolute path to the hook into `SKILL.md` and the agent files. The config folder is `~/.claude`, or the value of the `CLAUDE_CONFIG_DIR` variable if it is set.
- **Reinstalling.** If the skill is already installed, the previous version is kept next to it with the suffix `.bak-<date>`.
- **After installation**, restart the Claude Code session.
- **Without scripts.** You can copy manually: the folder `skill-en/revref` → `~/.claude/skills/revref`, the files `agents-en/*.md` → `~/.claude/agents/`, `CHANGELOG.en.md` → into the skill folder as `CHANGELOG.md`. Then replace `__REVREF_SKILL_DIR__` in `SKILL.md` and the agent files with the path to the skill folder (with forward slashes). Without this replacement the guard hook will be inactive.

## Quick start

1. Open the project in Claude Code and run `/revref init`. The agent asks up to 5 questions: autonomy level, critical parts, prohibitions, time budget, push. It then creates the run branch and the `.revref/` folder and records the baseline.
2. Check `.revref/CONFIG.md` and adjust it if needed.
3. Run `/revref run`. From here the run proceeds autonomously.
4. From time to time, run `/revref ask` to answer the most important questions right in the chat, or `/revref status` for a summary. The full queue is in `.revref/DECISIONS.md`.

## Commands

| Command | What it does |
|---|---|
| `/revref init` | Prepare the run (W0); the only interactive command |
| `/revref run` | Continue the pipeline or an unfinished queue from the current point to the end or until a stop condition |
| `/revref resume` | Reconcile with git (other people's commits, main branch, WIP), owner answers, checks — then `run` |
| `/revref checkpoint` | Record the full state now, to continue later anywhere |
| `/revref status` | Short summary from the files; changes nothing |
| `/revref decisions` | Show the whole approval queue and process your answers from the file |
| `/revref ask [N\|all]` | Show in the chat the highest-priority unanswered questions (1 by default) and accept the answers right away; can be entered while agents are working |
| `/revref review <list> [--verify\|--fix] [--optimal]` | One or more selected reviews in a single launch, in queue order (parameters below) |
| `/revref wave <Wn>` | Run a single wave |
| `/revref finish` | Merge the result into the `test` branch (test stand): decision review, trial merge, checks, stand checklist; merge and push — each after your "yes" |

## Command parameters

### `/revref review <list> [mode] [--optimal]`

| Parameter | Values | Default | What it does |
|---|---|---|---|
| `<list>` | Review ID (`SEC`), wave name (`W2`), `all`; separated by spaces or commas | — (required) | Which reviews to run. `W<n>` expands to the wave's reviews (`W1` and `W9` — to `QR`), `all` — to all applicable reviews of W2–W8. Duplicates are removed. If an ID is unknown, nothing is run |
| *(no mode flag)* | — | ✔ | Reports only. Reviews run in parallel, code is not changed, no branch is created, no commits |
| `--verify` | — | — | Reports plus independent verification of each: a fresh agent rechecks the findings and filters out false ones. Code is not changed |
| `--fix` | — | — | Full cycle for each review in turn: review → verification → plan → fixes → checks → milestone. Works in the run branch, with commits and `Q<n>-<ID>` tags. If there is no `.revref/`, full preparation with questions comes first |
| `--optimal` | — | — | Reorder the list according to the pipeline (QR, then W2 → W8). Without the flag the order is yours: if the order is risky, the agent warns you but still runs it |

`--verify` and `--fix` are mutually exclusive (`--fix` includes verification). `--optimal` can be combined with any mode.

### Other commands with arguments

| Command | Argument | What it does |
|---|---|---|
| `/revref ask [N\|all]` | a number or `all`; `1` by default | How many of the highest-priority questions for the owner to show in the chat |
| `/revref wave <Wn>` | `W0`…`W9` | Run a single pipeline wave, checking its entry conditions |
| `/revref` | *(no arguments)* | If a run exists — a short status and an offer to `resume`; if not — command help |

`init`, `run`, `resume`, `checkpoint`, `status`, `decisions` and `finish` take no parameters. Their behavior is configured in `.revref/CONFIG.md`.

### Run settings in `CONFIG.md`

| Setting | Default | Values |
|---|---|---|
| Autonomy level | balanced | cautious · balanced · bold |
| Fix threshold | Medium | Critical · High · Medium · Low; below the threshold — quick wins only |
| Monetary fixes per spec | class C | class C · class B (only fixes unambiguously prescribed by the spec, no change to prices or rules) |
| Reviews | all applicable | force-include / exclude IDs |
| Custom reviews | none | `ID → wave`, for example `VPN → W2` |
| Scope | whole repository | include / exclude paths |
| Parallelism | up to 4 subagents | a number |
| Time budget | unlimited | a duration or a date |
| Run branch | `revref/YYYY-MM-DD` | branch name |
| Main branch | `main` | branch name (the agent does not change it) |
| Target branch (`finish`) | `test` | branch name |
| Push | forbidden | forbidden · allowed for the run branch only |
| Merge method (`finish`) | ask | merge --no-ff · squash · pull request |
| `.revref/` on merge (`finish`) | ask | keep · archive · remove |
| Keep `.revref/` in git | yes | yes · no |
| Report language | English | any |

### Installers

| `install.sh` | `install.ps1` | What it does |
|---|---|---|
| *(no parameters)* | *(no parameters)* | Global installation into `$CLAUDE_CONFIG_DIR` or `~/.claude` |
| `--project <path>` | `-Project <path>` | Installation into a project only: `<path>/.claude` |
| `--uninstall` | `-Uninstall` | Remove the skill and the agents; can be combined with `--project` / `-Project`. `*.bak-*` backups are left untouched |
| `--lang ru\|en` | `-Lang ru\|en` | Kit language: prompts, protocols, templates, reports. Default: `ru` |
| `-h`, `--help` | `Get-Help ./install.ps1` | Short help |

## Working with git branches

```text
main ──────────────────────────────────────────────────────────────  never changed by the agent
  └─► revref/<date>                 run branch: all merged fixes + .revref/
        ├─◄ revref/task/<ID>        fixer task branches (worktree), merged by the orchestrator
        ├── revref/pending/D-NNN    class C decisions — not merged without the owner
        └── tags W<n>, Q<n>-<ID>, final
              └──/revref finish──►  test ──manually, after checking on the stand──►  main
```

### Branches

| Branch | Who creates it and when | Based on | What it contains | What happens next |
|---|---|---|---|---|
| `main` (main branch, `CONFIG.Main branch`) | — | — | The run's base | The agent only reads it. If it has moved ahead, it is merged into the run branch on `resume` and in `finish` |
| `revref/<YYYY-MM-DD>` | `init` (W0) | Current HEAD | All merged fixes, A and B decisions, the `.revref/` state | The source for `finish`; remains afterwards, you delete it |
| `revref/<YYYY-MM-DD>-q` | `review --fix`, if there is no run or it is finished | Current HEAD | The same for a queue | The same |
| `revref/task/<ID>` | Fixer, one per task | HEAD of the run branch | Commits of a single task | The orchestrator merges it after checks (`merge --no-ff`); merged ones are deleted in `finish` |
| `revref/pending/D-NNN` | Orchestrator, for a class C decision (or B at the cautious level) | HEAD of the run branch | A ready patch with tests | Merged only after your approval; unapproved ones remain |
| `test` (target branch, `CONFIG.Target branch`) | — | — | Test stand | `finish` merges into it after your "yes", push — after a separate "yes" |

### Commits

| Prefix | What the commit is |
|---|---|
| `revref(W0): run initialization` | Creation of `.revref/` and the baseline |
| `revref(W<n>): <task> <summary>` | A fix in a wave; trailers `Findings: BUG-07, EDGE-03` and `Decision: D-012` |
| `revref(Q<n>): <task> <summary>` | A fix in a `review --fix` queue |
| `revref(state): …` | Checkpoint, processing of owner answers, state after a task merge |
| `revref(wip): …` | Unfinished work committed at a checkpoint (instead of stash) |
| `revref(finish): …` | Steps of the `finish` command |

Every commit of the run branch contains code and the `.revref/` state consistent with it, so work can be resumed from any commit. The trailers show which finding and which decision a commit implements: `git log --grep "D-012"`.

### Tags

Created locally, not pushed automatically.

| Tag | Where | Why |
|---|---|---|
| `revref/<date>/W<n>` | Run branch, end of a wave | Rollback point to the state after the wave |
| `revref/<date>/Q<n>-<ID>` | Run branch, end of a queue item | The same for a queue |
| `revref/<date>/final` | Run branch before the merge | Full history of the run, including `.revref/`, even if you did not carry it over into `test` |
| `revref/<date>/merged` | Target branch after the merge | Marks which `test` commit contains the run's result |

### Rules

- **The agent never:**
  - changes `main`;
  - force-pushes or rebases published branches;
  - touches other people's uncommitted changes;
  - deletes other people's branches.
- **Push.** The run branch — only if allowed in `CONFIG.md`. The `test` branch — only in `finish` and only after a separate "yes", because this is a deployment to the stand.
- **The guard hook** technically blocks violations of these rules during a run, even if the agent makes a mistake (see the "Security" section).
- **Synchronization — only via merge, not rebase.** `main` is merged into the run branch, while `test` is never merged into the run branch: it may contain other people's unverified changes.
- **Rollback:**
  - a wave or a queue — `git revert` of its commit range (boundaries are given by the tags);
  - a single decision — `git revert` of its commits (`git log --grep "D-NNN"`);
  - the whole result on the stand — `git revert -m 1 <merge commit>` in `test`.

## Security

### Secrets

Reports, decisions and journals from `.revref/` are committed, reach `test` via `finish`, and from there go to `main` and possibly to a public repository. Therefore the values of keys, tokens, passwords and personal data never get into these files, commit messages or the chat. Instead of the value, the agent gives the location, the type and a masked form: `sk-l…9f`.

A secret found in the code is a SEC finding of at least High. The agent may remove it from the code itself. Rotating the key and cleaning git history is the owner's decision (class C): the agent cannot rotate the key and does not rewrite history.

### Prompt injection

Subagents read the whole project, including other people's code, generated files and test data. These may contain text addressed to an AI agent: "ignore the rules", "do a push". The kit treats project content and tool output as data, not instructions. Instructions are accepted only from the owner (chat, answers in `DECISIONS.md` and `INBOX.md`, `CONFIG.md`, custom reviews) and from the kit's files. An attempt to control the agent through text in the project becomes a SEC finding, and the owner gets a message in the chat.

### Guard hook

The git rules are backed by a technical limiter — the hook `skill-en/revref/hooks/guard.sh`. It is connected automatically through the frontmatter of the skill (in the main session after any `/revref` command) and of the agents (inside subagents), and it is active only while the repository contains `.revref/STATE.md`.

| Blocks | Examples |
|---|---|
| Changing the main branch | `commit`, `merge`, `reset`, `pull` on `main`; `checkout main && commit` |
| Pushing the main branch, force-push, deleting remote branches | `git push origin main`, `git push -f`, `git push origin +branch`, `git push --delete` |
| Rewriting history | `git rebase` (except `--abort`), `filter-branch`, `filter-repo` |
| Losing uncommitted work | `git clean -f`, `git stash drop`, `git checkout -- .`, `git restore .`, `git reset --hard` with changes present, `git branch -D` |
| Secrets | A secret in a commit message or in lines being added to `.revref/` and `docs/revref/` |

- A blocked command is not executed, and the agent receives an explanation in the run's language.
- Only the owner can disable the hook for a session: the environment variable `REVREF_GUARD=off`.
- On Windows, Claude Code hooks run through Git Bash. Without Git Bash the hook is inactive, and the rules rely on the policy alone.
- The hook is covered by tests: `sh scripts/test_guard.sh`.

## Result and merge

```text
main ──► revref/<date> ──/revref finish──► test (test stand) ──manually, after checking──► main
```

A run never merges anything anywhere on its own. The result is the `revref/<date>` branch with the fixes, pending branches with class C decisions, wave tags and `.revref/FINAL_REPORT.md`.

The `/revref finish` command merges the result into the target branch — `test` by default, configurable in `CONFIG.md`. **The agent never changes `main`:** you merge `test` into `main` manually after checking on the stand.

`finish` steps:
1. **Unanswered decisions.** The agent lists them and waits for an answer. You can answer in the chat, including in batch: "D-004 reject, confirm the rest of B". Unapproved behavior changes will not reach the stand. C decisions without an answer are considered rejected for this merge; their branches remain for the future.
2. **Processing the answers.** What was rejected is reverted together with dependent changes; approved pending branches are merged.
3. **Synchronization and trial merge.** A fresh `main` is merged into the run branch. Then a trial merge into `test` with checks is performed in a temporary copy. `test` is not merged into the run branch: it may contain other people's unverified changes.
4. **Summary and checklist.** What will be included and what will be left out, plus **`STAND_CHECKLIST.md`**: what to check on the stand and how, which variables and migrations the stand needs, how to roll back.
5. **Merge method** (merge, squash or PR into `test`) and what happens to `.revref/`. Remember that everything in `test` will later go to `main`.
6. **Merge into `test`** locally, after your "yes".
7. **Push `test`** (triggers the deployment to the stand) — after a separate "yes". Never force.
8. **Cleanup.** Merged temporary branches are deleted, the `merged` tag is set, and a final message is written with a reminder about the manual merge into `main`.

If you stop at any step, `finish` can be repeated later from the same point.

## Selective runs: a single review or a queue

The full pipeline is not mandatory: you can run any review on its own or build a queue of several.

```text
/revref review SEC                      a single security review, report only
/revref review SEC BUG EDGE --verify    three reports, each rechecked by an independent agent
/revref review TEST HYG DRY --fix       in turn: tests → cleanup → duplication, with fixes
/revref review W2 DX --fix --optimal    all reviews of wave W2 plus DX, reordered according to the pipeline
/revref review all                      reports for all applicable reviews
```

- **List.** IDs separated by spaces or commas. Wave names (`W2`, `W5`…) expand to their reviews, `all` — to all applicable ones.
- **Modes:**

  | Mode | What happens | Branch and commits |
  |---|---|---|
  | no flag | Reports only; reviews run in parallel | None, code is not changed |
  | `--verify` | Reports plus independent verification of each | None, code is not changed |
  | `--fix` | Each review in turn goes through the full cycle: review → verification → plan → fixes → checks → milestone with checkpoint. The next one starts after the previous one's checks | Run branch, commits, `Q<n>-<ID>` tags |

- **Order** — as you specified. If it is risky (for example, DRY with fixes before TEST, or documentation before refactoring), the agent warns you but still runs it. With `--optimal` the order follows the pipeline.
- **Decisions in a queue** are recorded in `DECISIONS.md` under the same policy as in the pipeline. After an interruption, the queue is resumed with `/revref resume`.
- **Launching during the pipeline.** The pipeline pauses at a step boundary and continues after the queue. Reviews performed in a queue with `--fix` are not repeated by the pipeline.
- **Queue summary** — in `.revref/reports/QUEUE-<date>.md`.

## The `.revref/` working folder in the project

| File | For whom and why |
|---|---|
| `CONFIG.md` | Your run settings and project context |
| `DECISIONS.md` | **The main file for the owner:** the approval queue and the log of all autonomous decisions. Answer in it or in the chat via `/revref ask` |
| `INBOX.md` | Owner answers from a parallel session or entered manually; the orchestrator transfers them to `DECISIONS.md` |
| `STATE.md` | Checkpoint: where the run is, what is in progress, what comes next |
| `CONTEXT.md` | Long-term memory: project map, commands, baseline, pitfalls, your instructions |
| `PLAN.md` | Review applicability, waves, tasks, groups, statuses |
| `FINDINGS.md` | Register of all findings and what happened to them |
| `JOURNAL.md` | Chronology of milestones |
| `reports/`, `tasks/` | Review reports and fixer notes |
| `FINAL_REPORT.md` | Run summary: what changed, what is waiting for you, how to merge the result |
| `STAND_CHECKLIST.md` | Created in `finish`: what to check on the stand and how, before merging into `main` |

`.revref/` is kept in git (by default), and every task commit contains a consistent state. That is why a run can be continued on any machine and in any session.

## How the owner answers decisions

### Right in the chat: `/revref ask`

```text
/revref ask          the highest-priority question
/revref ask 5        the five highest-priority ones
/revref ask all      all unanswered
```

The agent shows cards that you can answer without opening any files:

```text
[1/3] D-012 · 🔴 C · MONEY · blocks: W2-T04, W2-T07
Summary: rounding of invoice amounts — currently standard (half-up), discrepancy with the bank of up to 1 cent per line item
Now: patch ready in branch revref/pending/D-012, not merged into the run branch
Options:
  a) banker's rounding in the final calculation — recommended: matches bank statements
  b) standard, but only on the total amount
  c) leave as is
If not decided: tasks W2-T04 and W2-T07 are deferred
Answer: "D-012 ok" — accept the recommendation (a) · "D-012 b" · "D-012 otherwise: …" · "D-012 skip"
```

- **There is always a recommendation.** The recommended option comes first, under letter "a", with a reason. If the agent cannot recommend anything, it says why and what is missing to make the decision.
- **How to answer.**
  - `D-012 ok` — accept the recommendation;
  - `D-012 b` — choose another option;
  - several at once: `D-012 ok; D-015 reject`;
  - "all ok" — accept the recommendations for all shown cards;
  - if a single card is shown, the ID can be omitted;
  - `yes` / `no`, `otherwise: …`, `skip` (it will be shown later) and a counter-question `D-012 ?: …` are also accepted.
- **Display order:**
  1. the question the run is stopped on;
  2. whatever blocks the current work;
  3. class C, then B, then questions;
  4. severity of the related findings;
  5. age.
- **While agents are working.** The command can be entered while agents are working. In the orchestrator session it is processed immediately; running subagents are not interrupted. The answer is applied after the current task, and unblocked tasks go into work right away.
- **From a second session** in the same folder, answers are written to `.revref/INBOX.md`, and the orchestrator picks them up at the next step boundary. This way two sessions never edit `DECISIONS.md` at the same time.

### In the `DECISIONS.md` file

In `DECISIONS.md`, every decision has an "Owner decision" field. Write into it:
- `ok` — accept the agent's recommendation;
- `confirm`;
- `reject`;
- `otherwise: …`;
- a free-form question.

The agent processes the answer at the next step boundary or on `/revref decisions`:
- merges what was approved from the pending branch;
- reverts what was rejected, together with dependent changes;
- records general instructions ("money always in cents", "do not touch module X") in `CONTEXT.md`, and they stay in effect until the end of the run.

## Multi-day work

- **Permission mode.** For autonomy, the session needs permission to edit files and run commands without confirming each step (for example, auto mode). Destructive and external actions are forbidden by the kit's policy regardless of the mode.
- **The laptop must not go to sleep.** In the desktop app, turn on keep-awake.
- **Context compaction is not a problem.** The agent keeps everything needed to continue in files and rereads `STATE.md` after compaction.
- **Session dropped.** Open a new one and run `/revref resume`.
- **Planned break** or working on the project in parallel: `/revref checkpoint`, then commit to the main branch freely. On resume the agent will:
  - find other people's commits;
  - merge the main branch into the run branch;
  - mark affected findings as stale and recheck them;
  - update the baseline.

## Without Claude Code or without subagents

The kit also works in other agents (Cursor, Codex, Aider, etc.):
- Give the agent `skill-en/revref/ORCHESTRATOR.md` as the starting instruction and point it to the kit folder.
- If there are no subagents, the orchestrator performs the roles sequentially according to the descriptions in `roles/`. Verification is best done in a new session.

The individual review prompts from `skill-en/revref/prompts/reviews/`, together with `prompts/common-rules.md`, can also be used manually, as in v2.

## Versions and updates

- **Kit version** — in `skill-en/revref/VERSION`, change history — in [CHANGELOG.en.md](CHANGELOG.en.md). Versions follow semantic versioning: major — incompatible changes to the `.revref/` format, minor — new compatible features, patch — fixes.
- **Recording in the run.** On `init`, the version is written to `STATE.md`. On `resume`, the agent compares it with the installed one:
  - same major version — continues, performs the "Migration" sections from `CHANGELOG.md` (if any) and records the update in the journal;
  - a different major version or a rollback of the kit to an older version — stops and asks the owner.
- **Updating:**

  ```bash
  git pull && ./install.sh --lang en
  ```

  Reinstalling keeps the previous version of the skill next to it with the suffix `.bak-<date>`. A specific version can be installed from a tag: `git checkout v3.1.0 && ./install.sh --lang en`.

## Kit contents

```text
revref/
├── README.md, README.en.md   description in Russian and English
├── CHANGELOG.md, CHANGELOG.en.md
├── install.sh                installation: macOS, Linux, WSL, Git Bash
├── install.ps1               installation: Windows PowerShell 5.1, PowerShell 7+
├── scripts/                  kit self-check and tests (check_kit.py, test_guard.sh, test_install.*)
├── .github/workflows/        checks in GitHub Actions on Windows, macOS and Linux
├── agents/                   → ~/.claude/agents/ (Russian version; English — agents-en/)
│   ├── revref-reviewer.md
│   ├── revref-verifier.md
│   └── revref-fixer.md
├── skill-en/revref/          English version of the skill (installed with --lang en)
└── skill/revref/             → ~/.claude/skills/revref/ (Russian version; the English tree has the same layout)
    ├── SKILL.md                /revref commands
    ├── VERSION                 kit version
    ├── hooks/guard.sh          guard hook
    ├── ORCHESTRATOR.md         orchestrator role and main loop
    ├── PIPELINE.md             waves, steps, gates, overlaps, budget
    ├── POLICY.md               decision classes, labels, autonomy levels, git, prohibitions, stopping
    ├── PROTOCOLS.md            subagents, sharding, parallelism, checkpoint, resume, owner answers, merge (finish), questions in chat (ask)
    ├── roles/                  reviewer, verifier, fixer
    ├── prompts/
    │   ├── common-rules.md     general review rules
    │   ├── reviews/            QR + 21 specialized reviews
    │   └── work/               verify, plan, fix, final
    └── templates/              CONFIG, STATE, CONTEXT, PLAN, FINDINGS, DECISIONS, INBOX, JOURNAL, report, task, custom-review
```

## License

© 2026 [kesha4](https://github.com/kesha4). The kit is distributed under the [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/) license. The full text is in the [LICENSE](LICENSE) file.

You may freely use, copy, modify and distribute the kit, including for commercial purposes, provided you give attribution. Credit the author, link to the repository and the license, and indicate if you made changes. For example:

> Based on [RevRef](https://github.com/kesha4/revref) © kesha4, CC BY 4.0. Modified.
