# Fixing a task

Carry out one task of the wave plan: fix the findings it includes in your worktree and commit the result to the task branch `revref/task/<ID>`.

## Before you start

1. **Tree state.** Make sure the working tree is clean and you are on the task branch.
2. **Checks.** Run the tests, linter, type check and build with the commands from `.revref/CONTEXT.md` and record the initial state. What was already failing is not your regression, but note it in the notes.
3. **Materials.** Read the task's findings in the reports, including the verification verdicts and corrections.

## For each finding of the task

1. **Independent re-check.**
   - Reread the code and make sure the fix is really needed; do not rely on the review text.
   - If the finding is false or already fixed, note this in the notes and move on to the next one.
2. **Classification.**
   - Check the actual fix against the class from the packet per `POLICY.md`. If the fix turns out to be of a higher class (changes behavior, money, data, access, a contract, the interface), stop and return the task to the orchestrator with options.
   - If class B is allowed in the packet, make such a change as a separate commit, without unrelated edits.
3. **Test first.**
   - If there is no test and the regression risk is medium or high, first write a test that captures the problem (fails before the fix) or the current behavior (for a refactoring).
   - If a test is impossible, describe a manual check.
4. **Minimal fix** strictly within the scope of the finding, in the project's style. Do not fix new problems noticed along the way — write them in the notes.
5. **Checks.** Run the tests, linter, type check and build. Do not move on until the checks return to the initial state or better. If it does not work out in three attempts, roll back the changes for this finding and mark it as blocked with a description of the reason.
6. **Commit.** One logical change — one commit. Message: `revref(W<n>): <task ID> <summary>` (for a queue item — `revref(Q<n>): …`) and the trailer `Findings: <finding IDs>`.

## Decisions

If you had to choose between options along the way, record the decision in the notes:
- what was chosen and what the alternatives were;
- why this option was chosen;
- proposed labels per `POLICY.md`;
- how to roll it back.

The orchestrator will make the final entry in `DECISIONS.md`.

## Restrictions

- Changes to the public API, the data schema and major dependency upgrades — only if they are explicitly provided for by the task and allowed by the class.
- Do not disable or weaken tests. Note a flaky test in the notes.
- Do not push and do not merge the branch yourself.

## At the end

1. The notes `.revref/tasks/<ID>.md` are filled in per the template.
2. The final run of the checks is recorded in the notes.
3. Reply to the orchestrator in the format from the packet.
