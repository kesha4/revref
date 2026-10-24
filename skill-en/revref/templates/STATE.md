# RevRef run state

A checkpoint for continuing in any session. Written only by the orchestrator. Resume procedure — `PROTOCOLS.md §6`.

- Updated: YYYY-MM-DD HH:MM
- Kit version: X.Y.Z                  <!-- from VERSION at init; changes only when the kit is updated per PROTOCOLS.md §6 -->
- Checkpoint type: light | full | stopped: token limit (reset YYYY-MM-DD HH:MM) | run finished | ready to merge | run merged into <branch> <hash> | PR created <link>
- Run branch: revref/YYYY-MM-DD
- Run base commit: <hash> — where the run started
- HEAD before checkpoint: <hash>
- Mode: pipeline | queue
- Current wave and step: W<n> — <review | verification | plan | fixes | gate | milestone>
- Paused pipeline: — | W<n>/<step> (if a queue was started during the run)

## Queue

<!-- Only in "queue" mode. Launch command, mode and order — as set by the owner. -->

- Command: /revref review …
- Mode: reports only | --verify | --fix · order: as given | --optimal

| # | Review | Status | Report | Tag | One-line summary |
|---|---|---|---|---|---|

## Progress by wave

| Wave | Status | Started | Completed | Tag | One-line summary |
|---|---|---|---|---|---|
| W0 Preparation | pending | | | | |
| W1 Reconnaissance | pending | | | | |
| W2 Security and correctness | pending | | | | |
| W3 Foundation | pending | | | | |
| W4 Cleanup | pending | | | | |
| W5 Structure | pending | | | | |
| W6 Operations | pending | | | | |
| W7 Interface | pending | | | | |
| W8 Documentation | pending | | | | |
| W9 Final | pending | | | | |

## Counters

- Findings: total … · open … · confirmed … · fixed … · false … · deferred … · waiting for owner … · blocked … · stale …
- Decisions: total … · 🔴 C waiting … · 🟠 B waiting … · approved … · rejected …

## In progress

<!-- Every unfinished unit of work. Empty if everything is finished. -->

| What | Fixer | Branch or worktree | Files | Done | Remaining |
|---|---|---|---|---|---|

## Next actions

<!-- Executable without memory of the session: concrete IDs, files, commands. The first item is what to do right after resuming. -->

1.
2.
3.

## Waiting for owner

<!-- Links to D-NNN and what each decision blocks. -->

## Checks

| Check | Baseline | Now | Comment |
|---|---|---|---|
| Tests | | | |
| Linter | | | |
| Types | | | |
| Build | | | |

## Uncommitted and WIP

<!-- WIP commits, task branches, subagent worktrees not yet merged — with a description. -->

## Notes for the next session

<!-- Short-lived things that do not belong in CONTEXT.md: hypotheses being checked, what was tried and did not work, what to pay attention to. -->
