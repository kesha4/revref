# Verification of findings

Re-check the assigned findings of a review report. Act as an independent expert whose job is to weed out false and exaggerated findings before time is spent on them.

## For each finding

1. **Reopen the code** at the stated locations on the current HEAD. If the code has changed since the report's base commit, check the current state. Do not rely on the reasoning in the report.
2. **Confirm** if possible: by reproduction, a test, running a tool, tracing the data path.
3. **Check whether the case is handled elsewhere:** higher up the stack, in middleware, in the framework, in configuration, in infrastructure, in validation on another layer.
4. **Assess the scales:** is the severity overstated, is the regression risk understated, is the effort realistic.
5. **Three questions about the proposed fix** — mandatory for Critical, High and Medium, brief for Low:
   1. **Is the premise right?** Compare with the specification and its appendices, with the decisions taken (`DECISIONS.md`, "Owner instructions" and "Sources of intended behavior" in `CONTEXT.md`) and with the real operating process: is it really a defect or intended behavior? Intended — verdict "False" with a reference to the source; sources contradict each other — "Needs information".
   2. **What does the fix forbid or change for an honest user?** List the legitimate scenarios that used to work and after the fix will get a refusal or a different result: other clients and roles, unusual but valid input, automations and integrations. Every such scenario is an owner decision (label `LEGIT`), not a silent code change.
   3. **Regression risk.** What else the change affects: other call sites and modules, other clients, an old client version during an update (the server is already new, the client still old, and vice versa), the minimum supported platforms from `CONTEXT.md` → "Platforms, clients and environments", the server, containers, deployment. Check not only with tests but also by reading the code: find all consumers of the functions, fields, formats and settings being changed.

   If there is a better fix, propose it.
6. **Check the decision labels:** if the fix touches money, data, access, behavior, contracts or the interface, and the labels are missing or understated, add them.
7. **Refine the affected files:** the full list is needed for planning parallel work.

## Verdict

Write it into the finding's "Verification verdict" field:

```text
- Verification verdict: Confirmed | Confirmed with corrections | False | Needs information | Stale (code changed, the problem is gone)
  Rationale: <1–3 lines with evidence>
  Corrections: <changed severity, confidence, fix, labels, files — if any>
  Premise: <defect | intended behavior (source) | unclear>
  Legitimate scenarios the fix will change: <list or "none">
  Regression risk: <what it affects; how checked — tests, code reading, version compatibility, platforms>
  Question: <for "needs information" — what exactly and whom to ask>
```

Do not delete false findings.

## At the end

At the end of the report, in the "Verification summary" section:
- how many findings were checked, confirmed, confirmed with corrections, false, need information;
- the updated top 5.
