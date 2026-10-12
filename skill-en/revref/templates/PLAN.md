# RevRef run plan

Written by the orchestrator. The owner may change the applicability matrix and the order; changes take effect at the boundary of the next wave step.

## Applicability matrix

<!-- Filled in at W1 based on QR and CONFIG. Custom reviews from .revref/reviews/ are added as rows in their wave. -->

| Review | Wave | Decision | Reason / focus |
|---|---|---|---|
| SEC | W2 | run | |
| DEP | W2 | | |
| BUG | W2 | | |
| DATA | W2 | | |
| EDGE | W2 | | |
| RES | W2 | | |
| TEST | W3 | | |
| DX | W3 | | |
| HYG | W4 | | |
| ARC | W5 | | |
| DEC | W5 | | |
| DRY | W5 | | |
| PERF | W6 | | |
| OBS | W6 | | |
| API | W6 | | |
| I18N | W6 | | |
| RWD | W7 | | |
| A11Y | W7 | | |
| CMT | W8 | | |
| SPEC | W8 | | |
| UDOC | W8 | | |

## Special run conditions

<!-- For example: "no tests — W3 is mandatory before W4–W5", "W7 runs in parallel with W4–W6". -->

## Queue

<!-- Selective /revref review launches — each as a separate subsection:

### Q-YYYY-MM-DD — /revref review TEST HYG DRY --fix
Mode: --fix · order: as given · order warnings: …

| # | Review | Status | Tasks | Tag | Summary |
|---|---|---|---|---|---|
| Q1 | TEST | completed | Q1-T01…T04 | revref/2026-10-14/Q1-TEST | reports/TEST.md |

Tasks for items with --fix — in the format of prompts/work/plan.md, with IDs like Q<n>-T<nn>.
-->

## Waves

<!-- Wave sections are added in the format from prompts/work/plan.md as planning proceeds. -->
