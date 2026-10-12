# Verification of findings

Re-check the assigned findings of a review report. Act as an independent expert whose job is to weed out false and exaggerated findings before time is spent on them.

## For each finding

1. **Reopen the code** at the stated locations on the current HEAD. If the code has changed since the report's base commit, check the current state. Do not rely on the reasoning in the report.
2. **Confirm** if possible: by reproduction, a test, running a tool, tracing the data path.
3. **Check whether the case is handled elsewhere:** higher up the stack, in middleware, in the framework, in configuration, in infrastructure, in validation on another layer.
4. **Assess the scales:** is the severity overstated, is the regression risk understated, is the effort realistic.
5. **Check the fix:** is the proposed fix correct and does it create new problems. If there is a better fix, propose it.
6. **Check the decision labels:** if the fix touches money, data, access, behavior, contracts or the interface, and the labels are missing or understated, add them.
7. **Refine the affected files:** the full list is needed for planning parallel work.

## Verdict

Write it into the finding's "Verification verdict" field:

```text
- Verification verdict: Confirmed | Confirmed with corrections | False | Needs information | Stale (code changed, the problem is gone)
  Rationale: <1–3 lines with evidence>
  Corrections: <changed severity, confidence, fix, labels, files — if any>
  Question: <for "needs information" — what exactly and whom to ask>
```

Do not delete false findings.

## At the end

At the end of the report, in the "Verification summary" section:
- how many findings were checked, confirmed, confirmed with corrections, false, need information;
- the updated top 5.
