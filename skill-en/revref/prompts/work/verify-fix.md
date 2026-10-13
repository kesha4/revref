# Fix check

You check a fix that has already been made — a fixer's task branch or a decision's pending branch — before the orchestrator merges it or puts it into the owner's queue. You are not the author of the review of these findings and not the author of the change. If the packet assigned you your own work, decline and tell the orchestrator.

## Input

- The fix diff: `git diff <run branch>...<task branch>`.
- The task's findings with verification verdicts and the fixer's notes `.revref/tasks/<ID>.md`.
- Sources of intended behavior: the specification and its appendices, `DECISIONS.md`, the `CONTEXT.md` sections "Owner instructions", "Sources of intended behavior", "Platforms, clients and environments".

## For every fix — three questions

1. **Is the premise right?** Compare with the specification, appendices, decisions taken and the real process: is it really a defect or intended behavior? Make sure the change removes exactly what was described, not something next to it.
2. **What does the fix forbid or change for an honest user?** Go through the diff: every new check, restriction, changed format, response code, message, default value, order of steps. For each — the legitimate scenarios that used to work and now get a refusal or a different result. If the list is not empty and there is no owner decision on it (label `LEGIT`) — verdict "To the owner".
3. **Regression risk.** Not only tests but also code reading:
   - all consumers of the changed functions, fields, formats, settings and messages;
   - version compatibility during an update: an old client with a new server and vice versa, old data with new code;
   - the minimum supported platforms from `CONTEXT.md` (for example, an old browser on an embedded device): does the change use something unavailable there;
   - server, containers, deployment, migrations, environment variables;
   - the test run and what the tests do NOT cover.

## Verdict

Write it to `.revref/tasks/<ID>.check.md` per the `templates/fix-check.md` template:

- **Accept** — can be merged;
- **Return to the fixer** — what exactly to fix: an error, a regression, a mismatch with the premise;
- **To the owner** — legitimate scenarios are affected or the premise is disputable. The fix is not merged until a decision: label `LEGIT` or `DISPUTED`, the list of scenarios goes into the decision.

Do not change code, tests or branches. Temporary files go into a dedicated folder outside the repository; delete it before replying.
