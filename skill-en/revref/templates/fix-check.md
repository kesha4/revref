# Fix check <task ID>

- Branch: revref/task/<ID> | revref/pending/D-NNN · range: <base>..<head>
- Checker: <agent> · not the author of the review or the change: yes

## Fixes

### <finding or commit>
- Premise: defect | intended behavior (source) | unclear — rationale
- Legitimate scenarios that will get a refusal or work differently: <list> | none
- Regression risk: <what it affects>
- Checked: tests <…> · code reading <consumers…> · version compatibility <…> · platforms <…> · server, containers, deployment <…>
- Not covered by tests: …

## Verdict

Accept | Return to the fixer (what to fix) | To the owner (scenarios and premise — into decision D-NNN)
