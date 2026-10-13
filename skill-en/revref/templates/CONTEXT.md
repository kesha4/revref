# Project context

The run's long-term memory: stable facts about the project that any agent needs in any session. Written by the orchestrator, who keeps it up to date: removes what is outdated rather than appending "now it is different". Target — no more than ~300 lines. Details are in the reports; here only the essence and links.

## Project

- Purpose:
- Users:
- Stack and versions:
- Size: files … · lines … (by language)

## Module map

| Module or path | Responsibility | Depends on | Notes |
|---|---|---|---|

Entry points:
External systems (DB, APIs, queues, file storage):

## Platforms, clients and environments

<!-- Who uses the system and with what — to assess the regression risk of every fix. -->

- Clients and their versions, including old ones that keep working during an update:
- Minimum supported platforms (browsers, OSes, devices — for example, an old browser on an embedded device):
- Server, containers, deployment; how updates roll out (all at once or gradually), compatibility of an old client with a new server:

## Sources of intended behavior

<!-- Where to check whether something is a defect or intended. -->

- The specification and its appendices (decisions, agreements):
- The owner's decisions: `DECISIONS.md`, "Owner instructions" below
- The real operating process (who uses the system, when and how):

## Commands

<!-- Each one verified by running it. The run may continue on another machine, so state the environment where it was verified. If commands differ between OSes, give the variants in the "Notes" column or as separate rows. -->

Verified in environment: <OS, shell, runtime versions>

| Action | Command | Time | Notes |
|---|---|---|---|
| Install | | | |
| Run | | | |
| Tests | | | |
| Tests for one file | | | |
| Linter | | | |
| Type check | | | |
| Build | | | |
| Coverage | | | |
| Dependency audit | | | |

## Baseline

<!-- The state of checks at the START of the run — the "no worse than the baseline" reference for gates. The current state lives in STATE.md → "Checks". Do not update it as work progresses. -->

- Recorded: YYYY-MM-DD, commit <hash>
- Tests: total … · failing … (which) · time …
- Coverage: …
- Linter: errors … · warnings …
- Types: errors …
- Build: succeeds / fails · time …
- Vulnerable dependencies: critical … · high … · moderate …
- Other metrics (bundle size, response time…):

<!-- When the baseline is updated after merging the main branch — a new entry with the reason; do not delete the old one. -->

## Project conventions

<!-- Code style, naming, structure, commit format, comment language — as is customary in the project. -->

## Quirks and pitfalls

<!-- Generated code, flaky tests, slow steps, non-obvious dependencies, "do not run X without Y". -->

## Domain glossary

## Owner instructions

<!-- Long-term preferences and prohibitions from the owner's answers — with a link to D-NNN. They take priority over review recommendations. -->
