# Final run report

Compile `.revref/FINAL_REPORT.md`. The reader is the project owner who did not follow the run. The report should give the full picture in 5 minutes, with all the details behind the links.

## Structure

1. **Summary in five lines:**
   - what got better;
   - what remains the main risk;
   - how many decisions are waiting for the owner;
   - the recommended next action.
2. **Requires your decision.** A table from the `DECISIONS.md` queue: 🔴 C first, then 🟠 B.
   - For each decision: ID, labels, summary in one sentence, whether it is implemented (commit or pending branch), the agent's recommendation, what happens if it is not decided.
   - How to answer — a link to the header of `DECISIONS.md`.
3. **Before → after.** Comparison with the baseline from `CONTEXT.md`:
   - tests (count, failures, coverage);
   - linter warnings and type errors;
   - vulnerable dependencies;
   - code size;
   - build and test time;
   - performance metrics, if measured;
   - QR maturity scores in W1 and W9.
4. **By wave.** For each wave: reviews performed, how many findings were found, confirmed, fixed, deferred, false; key changes; commit range and tag.
5. **Behavior changes.** All merged decisions with the labels `BEHAVIOR`, `BUSINESS`, `UX`, `CONTRACT`, `DEPENDENCY`, grouped so they can be checked manually: what changed, how to check, how to roll back.
6. **Deferred and blocked.** A list with reasons and a recommendation on when to return to it.
7. **Skipped reviews** and the reasons for skipping.
8. **Recommendations for the next cycle:** what to repeat and when, which practices to adopt so the problems do not return (CI checks, linter rules, templates).
9. **How to merge the result.** The run branch and pending branches, what to check before merging. To merge the result: `/revref finish`. The command will go through unanswered decisions with you, sync the branch with the main branch, do a trial merge into the target branch (`test`) with checks, prepare a checklist for checking on the stand, and merge only after your explicit "yes". Push to the stand — with a separate "yes". The main branch is updated manually after checking on the stand. `finish` will add the "Merge" section.
