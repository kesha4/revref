# RevRef pipeline

## Waves

| Wave | Name | Reviews | Fix goal | Overlap |
|---|---|---|---|---|
| W0 | Preparation | — | Branch, working folder, baseline, project map | — |
| W1 | Reconnaissance | QR | No fixes: review applicability, distributing findings across waves | — |
| W2 | Security and correctness | SEC, DEP, BUG, DATA, EDGE, RES | Vulnerabilities, data loss and corruption, bugs, failures | — |
| W3 | Foundation | TEST, DX | Safety net: tests for critical paths, characterization tests for areas of future refactoring, linters, formatter, CI | — |
| W4 | Cleanup | HYG | Remove dead code and clutter | — |
| W5 | Structure | ARC, DEC, DRY | Architectural changes → decomposition → removing duplication | — |
| W6 | Operations | PERF, OBS, API, I18N | Performance, observability, contracts, localization | Reviews can start during W5 fixes |
| W7 | Interface | RWD, A11Y | Responsiveness and accessibility | Can run in parallel with W4–W6 |
| W8 | Documentation | CMT, SPEC, UDOC | Comments, technical documentation, user documentation | — |
| W9 | Final | QR (delta) | Final check, comparison with the baseline, final report | — |

**Why this order.**
- First, what can cause harm right now (W2).
- Then the safety net, without which refactoring is dangerous (W3).
- Then removing clutter, so as not to refactor dead code (W4).
- Then structure, from large to small (W5).
- Documentation comes last, because all previous waves change it (W8).

The order of waves also reflects decreasing value: if the run stops early, the most important work is already done.

**Why reviews run inside a wave rather than all at once.** A review done before the fixes of earlier waves goes stale: lines shift, code is deleted, problems disappear or change shape. A wave's reviews are carried out on code already cleaned up by the previous waves.

## Custom reviews

Besides the 22 built-in reviews, a project can have its own — for the specifics of its domain, regulatory requirements, internal standards.

| File | What it is |
|---|---|
| `.revref/reviews/<ID>.md` | A new review. Template — `templates/custom-review.md` |
| `.revref/reviews/<ID>.extra.md` | An addendum to a built-in or custom review: the reviewer receives both files. For example, `SEC.extra.md` with the specifics of a VPN protocol |

- **ID** — 2–8 uppercase Latin letters or digits, not matching any built-in ID. It is also the finding prefix and the report name.
- **Wave** is set in `CONFIG.md` → "Custom reviews" (`VPN → W2, GDPR → W8`). If it is not set, the orchestrator assigns a wave in W1 based on the review's topic and records the choice with its rationale in `PLAN.md`.
- **Check in W0/W1.** There is a heading and a clear focus, the ID does not collide with built-in ones. A file with an error is a question for the owner; the review is skipped until the answer arrives.
- **Participation in the work.** Custom reviews are included in the applicability matrix, expand in wave names and in `all`, are accepted by the `review` command (`/revref review VPN --fix`), and go through the same wave steps, verification and decision policy.
- **Source of instructions.** Custom reviews count as owner instructions (POLICY.md → "Source of instructions"), so only the owner changes them, not the run's agents.

## Wave steps

### 1. Review
- For each applicable review of the wave (per the matrix in `PLAN.md`), launch a reviewer subagent with a task packet (PROTOCOLS.md §1). All reviews of the wave run simultaneously, within `CONFIG.Parallelism`.
- Large project — sharding by module (PROTOCOLS.md §2).
- Include in the packet the "in passing" findings of other reviews that relate to this review's topic: the reviewer confirms or refutes them in its report.
- The result is `reports/<ID>.md`. Add the findings to `FINDINGS.md` with the status "open".

### 2. Verification
- For each report — a fresh verifier subagent (`prompts/work/verify.md`), not the one that did the review. A large report is split among several verifiers by groups of findings or by shards; each writes verdicts to its own file `reports/<ID>.verdicts-<k>.md`, and you transfer them into the report — one file has one writer.
- Critical, High and Medium are checked one at a time, Low — as a batch, with a quick check.
- Transfer the verdicts to `FINDINGS.md`. False findings stay in the registry with a mark — this protects against them reappearing.

### 3. Wave plan
- Draw up a plan following `prompts/work/plan.md` and write it to `PLAN.md`.
- Tasks include:
  - confirmed findings at the `CONFIG.Fix threshold` level and above;
  - Low — only quick wins (effort S, low regression risk);
  - findings seen in passing by other reviews that relate to the wave's topic.
- For each task:
  - findings;
  - expected set of files;
  - dependencies;
  - decision class per POLICY.md;
  - effort.
- Groups: tasks within a group do not overlap in files and are executed in parallel; groups run sequentially.
- Class C tasks are not executed: they go straight to the `DECISIONS.md` queue (with a patch in a pending branch, if the autonomy level says so). Class B tasks — according to the autonomy level.
- **W5 specifically.** First ARC tasks, then DEC, then DRY. When recommendations conflict, architecture takes priority, and the conflict is recorded in `DECISIONS.md` with the label DISPUTED.

### 4. Fixes
- Each task is carried out by a fixer subagent (`prompts/work/fix.md`). Parallel fixers work in isolated worktrees, and you merge their branches one at a time (PROTOCOLS.md §3).
- **Fix check before merging.** A finished task branch is checked by a fresh verifier — not the review author and not the fixer — per `prompts/work/verify-fix.md`: is the premise right, what the change forbids or changes for an honest user, regression risk (tests and code reading).
  - "Accept" — merge.
  - "Return to the fixer" — a new iteration of the task.
  - "To the owner" — do not merge: the branch becomes `revref/pending/D-NNN`, a decision labelled `LEGIT` or `DISPUTED` with the list of affected scenarios goes into `DECISIONS.md`.
  - Patches for class C pending branches are checked the same way, before being queued.
- After each merged task:
  - run the checks;
  - update `FINDINGS.md`;
  - add the fixer's decisions to `DECISIONS.md` (you assign the final class and labels);
  - make a light checkpoint.
- The fixer's new findings go to `FINDINGS.md` with the status "open": into the current wave if on topic, otherwise into the appropriate one.

### 5. Wave gate
A wave is complete when all conditions are met:
- tests, linter, type check and build are no worse than the baseline: no new failures and no new warnings;
- every finding of the wave's topic has a final status: fixed / false / deferred / waiting for owner / blocked (with an explanation);
- no open Critical of the wave's topic, except those waiting for the owner;
- `PLAN.md`, `FINDINGS.md`, `DECISIONS.md` are consistent with git.

If the gate is not passed:
1. No more than two attempts to fix.
2. Then roll back the problematic tasks via `git revert`, give them the status "blocked" with a description of the reason, and pass the gate again.

### 6. Milestone
- Entry in `JOURNAL.md`: results, counters, commit range, notes.
- Tag `revref/<run date>/W<n>` — a rollback point.
- **Refresh pending branches.** If the wave changed files touched by `revref/pending/*` branches, update them to the run branch with merge commits (no rebase), make sure `git merge-tree` is clean, and check a trial merge of all pending branches together in a temporary worktree. Resolve conflicts and silent duplicates (classes, constants, identically named tests) immediately; record the remaining merge specifics in the decisions' "Dependent changes". Otherwise the branches go stale by `finish`, and an automatic merge can silently disable tests.
- Full checkpoint (PROTOCOLS.md §5).
- A short message in the chat.
- Check the owner's answers in `DECISIONS.md`.

## W0 — Preparation

1. **Git.**
   - If there is no repository — stop and suggest `git init`.
   - If the working tree has uncommitted changes — do not touch them: ask the owner whether to commit them separately or abort the start.
   - Create the run branch from `CONFIG` (by default `revref/<YYYY-MM-DD>`) from the current HEAD.
2. **Working folder.** Create `.revref/` from `templates/` (except `report.md`, `task.md` and `custom-review.md` — these are templates for reports, tasks and custom reviews), as well as `reports/`, `tasks/` and `reviews/`. Write the kit version from `VERSION` to `STATE.md`.
3. **Questions for the owner** — up to 5, the only interactive point of the run:
   - autonomy level;
   - critical parts of the project;
   - what must not be touched;
   - time budget;
   - whether push is allowed.

   Whatever you did not ask, determine yourself and mark it in `CONFIG.md` as an "assumption".
4. **Project map** → `CONTEXT.md`: purpose, stack, modules and their responsibilities, entry points, external systems, size (files and lines by language); clients, platforms and environments; sources of intended behavior (the specification and its appendices, decisions taken, the real process).
5. **Commands** → `CONTEXT.md`: install, run, tests, linter, type check, build, coverage, audit. Verify each command by running it.
6. **Baseline** → `CONTEXT.md`: run all checks and record the results: number of tests and failures, linter warnings, type errors, run times, coverage and vulnerabilities, if available. What was failing before the run is not a regression, but a task for W2 or W3.
7. **If there are no tests or very few:**
   - W3 is mandatory before W4–W5;
   - every W2 fix is accompanied by a test or an explicitly described manual check;
   - note this in `CONTEXT.md` and `PLAN.md`.
8. **Commit** `revref(W0): run initialization`, full checkpoint.

## W1 — Reconnaissance

1. **Quick review QR** (`prompts/reviews/QR.md`): one subagent or shards by module with merging.
2. **Verification.** Mandatory for Critical and High, optional for the rest.
3. **Applicability matrix** in `PLAN.md`: for each review W2–W8, including custom reviews from `.revref/reviews/` — "run", "skip" (why) or "narrow focus" (to what). Take into account `CONFIG.Reviews` (force-included and excluded) and QR's recommendations. Inapplicable reviews are skipped with the reason recorded, for example: "A11Y — no UI".
4. **Distributing findings.** Distribute QR's findings across waves by topic; they will go into the packets of the corresponding reviews as findings seen in passing.
5. **Out-of-turn task.** If QR found a Critical that is dangerous to leave until W2 (an active vulnerability, ongoing data corruption), make it the first task of W2 and inform the owner.
6. **Milestone.**

## W9 — Final

1. A full run of the checks and comparison with the baseline.
2. **QR delta** — a quick repeat review:
   - what improved;
   - what got worse;
   - whether refactoring introduced new problems;
   - whether there are inconsistencies between parts changed in different waves.

   Critical and High found here are fixed through the usual steps; the rest goes into recommendations.
3. `FINAL_REPORT.md` per `prompts/work/final.md`.
4. Final checkpoint marked "Run finished".
5. Message to the owner: where the final report is, how many decisions await approval (by classes C and B), which `revref/pending/*` branches await a decision, what is recommended next. To merge the result into the target branch (`test`), run `/revref finish`. The run itself merges nothing anywhere, and the agent never changes the main branch.

## Review queue (selective run)

The command `review <list> [--verify | --fix] [--optimal]` runs the selected reviews outside the full pipeline. Roles, protocols, policy and `.revref/` files are the same, so the queue likewise survives a session interruption and is resumed via `resume`.

### Parsing the list

1. **Expanding names.** Wave names expand into their reviews (`W2` → SEC DEP BUG DATA EDGE RES and custom reviews assigned to W2; `W1` and `W9` → QR). `all` → all reviews W2–W8, including custom ones, applicable per the `PLAN.md` matrix; if there is no matrix — all except those clearly inapplicable.
2. **Unknown ID** (neither a built-in prompt nor `.revref/reviews/<ID>.md`). Do not start work: report which IDs are valid.
3. **Duplicates** are removed; the first occurrence stays. An empty list is allowed only with the "commits" scope (`--commits`, `--since`, `--until`) — then it is QR in changes mode.
4. **Order.** Without `--optimal` — the owner's order. With `--optimal` — pipeline order: QR, then W2 → W8, within a wave — as in the waves table.
5. **Inapplicable reviews** (for example, RWD with no UI) are skipped with the reason recorded; the queue continues.
6. **Recording the queue.** Before starting work, write the queue to `PLAN.md` → "Queue" and to `STATE.md`: mode "queue", items, current item.

### Order warnings

The owner's order is respected. If it is risky, warn in one line in the chat, record it in `JOURNAL.md` and continue:
- **Refactoring without a safety net.** HYG, DEC, DRY or ARC with `--fix` when there are no tests for the affected areas and TEST does not come earlier in the queue. Fixers write characterization tests before changes anyway, but this is slower and riskier.
- **Small before large.** DEC or DRY come before ARC: architectural changes may redo what was just done.
- **Documentation before code.** CMT, SPEC or UDOC come before reviews with `--fix` that change code: the documentation may be stale by the end of the queue.

### Preparation

- **No `.revref/`, "reports only" mode or `--verify`.** Lightweight preparation without questions:
  - `.revref/` from templates, `CONFIG.md` with "(assumption)" marks;
  - project map and commands in `CONTEXT.md`;
  - no run branch is created, nothing is committed — the code does not change, and the `.revref/` files remain in the working tree at the owner's discretion.
- **No `.revref/`, `--fix` mode.** A full W0: questions for the owner, run branch, baseline.
- **Pipeline in progress.** Wait for the boundary of the current wave step and pause the pipeline: write "Paused pipeline: W<n>/<step>" in `STATE.md`. The queue runs in the same branch; after it, `run` resumes the pipeline.
- **Previous run finished or the current branch is not a run branch, `--fix` mode.** Create the branch `revref/<YYYY-MM-DD>-q` from the current HEAD and update the baseline in `CONTEXT.md`.

### Execution

- **Reports only.** The queue's reviews are launched in parallel within `CONFIG.Parallelism`: they are independent and do not change code. Findings are entered into `FINDINGS.md`; results go to the chat and the journal in queue order.
- **`--verify`.** The same, plus verification of each report as soon as it is ready, without waiting for the others.
- **`--fix`.** Queue items are executed strictly one at a time. Each is a mini-wave with steps 1–6 from "Wave steps":
  - milestone tag: `revref/<date>/Q<n>-<ID>`;
  - after each item — a full checkpoint;
  - the next item starts after the previous one's gate, because fixes change the code;
  - an early review of the next item is allowed under the "Wave overlap" rules.
- **Findings seen in passing** by reviews that are not in the queue are not fixed: they remain in `FINDINGS.md` with the status "open" for future runs. Exception — Critical: inform the owner and suggest adding the corresponding review to the queue.
- **Decisions** are made per `POLICY.md`, as in the pipeline.

### Completion

1. **Queue summary.** `.revref/reports/QUEUE-<YYYY-MM-DD>.md` per `prompts/work/final.md` in shortened form:
   - sections 1 and 2;
   - section 3 — only with `--fix`;
   - section 4 — by queue items instead of waves;
   - sections 5 and 6.
2. **Applicability matrix in `PLAN.md`.**
   - Reviews performed with `--fix` are marked "done in queue <date>"; the pipeline does not repeat them until the owner explicitly includes them again.
   - Reports without `--fix` are later used by the pipeline as findings seen in passing for their wave, with re-verification if the code has changed.
3. **Returning to the pipeline.** If the pipeline was paused, set the mode in `STATE.md` back to "pipeline".
4. **Checkpoint** (with `--fix` — with a commit) and a short message in the chat: what was done, how many decisions await the owner, where the summary is.

## Review of changes (scope — commits)

The `--commits`, `--since` and `--until` parameters of the `review` command narrow the scope of any review to the changes of the selected commits. Without a review list, QR runs in changes mode.

### Commit set

1. **Determine the set** on the current branch:
   - `--commits N` — `git log -n N`;
   - `--commits <from>..<to>` — `git log <from>..<to>`;
   - `--commits <sha>,<sha>` — each SHA via `git rev-parse --verify`; an ambiguous or missing SHA — stop and ask;
   - `--since` / `--until` — `git log --since=… --until=…` by commit date in the machine's time zone;
   - `--commits N` together with `--since` / `--until` — the last N commits of the period.
2. **An empty set** — report it and do not start the review. Merge commits are assessed by their changes relative to the first parent.
3. **Record the set** in `PLAN.md` → "Queue" and in `STATE.md`: SHA, author, date, subject, a summary of changed files (`git diff --stat`).
4. **Diff.** A contiguous set (last N, a range, a period without gaps) — one combined diff from the parent of the first commit to the last one; commits listed out of order — the diff of each separately (`git show <sha>`).

### Packet and report

- **The packet's "Scope" field:** the commit set, diff commands, the list of changed files. The reviewer also reads the surroundings of the changes — call sites, consumers of the changed functions, formats and settings — but findings are limited to what these commits introduced or affected.
- **Report:** `reports/<ID>.changes-<YYYY-MM-DD>[-<n>].md`; finding IDs — `<ID>-c<NN>` (for example, `SEC-c03`), so they do not clash with a full review.
- **Origin.** Every finding has the field "Origin: introduced <sha> | aggravated <sha> | pre-existing". Problems that existed before these commits in unchanged code go only to "Seen in passing" unless the changes affect them.
- **Verification** (`--verify`, `--fix`) and fix checks — as usual; the verifier also checks the finding's origin.

### Fixes (`--fix`)

- Fixes go into the run branch, as in an ordinary review queue: the run branch is created from the current HEAD, not from the selected commits.
- If the selected commits are not in the history of the current branch (another branch), only reports are produced, without `--fix`; say so.

## Wave overlap

- **Early review.** A review of the next wave can be launched while the current wave's fixes are in progress, if the review's scope does not overlap with the files of active tasks. The report records the base commit, and verification checks the findings against the current code.
- **W7 in parallel with W4–W6**, if the UI files do not overlap with the tasks of those waves.
- **Fixes of different waves are not carried out simultaneously,** except for W7.

## Time budget and early completion

- If `CONFIG.Time budget` is running out:
  1. Finish the current task.
  2. Mark the wave's remaining tasks "deferred (budget)".
  3. Skip the remaining waves.
  4. Perform a shortened W9: run the checks, `FINAL_REPORT.md`, checkpoint.
- If the owner changes `PLAN.md` or `CONFIG.md` during the run, the changes take effect at the boundary of the nearest step. Record this in `JOURNAL.md`.
