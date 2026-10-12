# Wave plan

Draw up the fix plan for the current wave and write it to `.revref/PLAN.md`, in the wave's section.

## Inputs

- Findings on the wave's topic with statuses "confirmed" and "confirmed with corrections" from `FINDINGS.md`.
- Findings seen in passing by other reviews that relate to the wave's topic.
- Findings with status "stale" if their re-verification confirmed them.
- The fix threshold from `CONFIG.md`. Low is taken only if it is a quick win (effort S, low regression risk).
- Owner answers and "Owner instructions" from `CONTEXT.md`.

## Steps

1. **Remove duplicates.** One problem from different reviews — one task with references to all source IDs.
2. **Find conflicting recommendations.** For example, DRY proposes merging what ARC proposes splitting, or PERF proposes a cache that DATA considers a source of inconsistency.
   - If the choice is technical and obvious, decide yourself.
   - Otherwise — a decision with the `DISPUTED` label in `DECISIONS.md`.
3. **Form tasks.** A task is a coherent unit of work for one fixer, usually up to a day. Split large findings into tasks, each of which leaves the project working.
4. **Determine the decision class** of each task per `POLICY.md`, based on the findings' labels and your assessment:
   - class C — into the `DECISIONS.md` queue, not scheduled for execution;
   - class B — according to the autonomy level.
5. **Account for dependencies:**
   - tests — before refactoring the same area;
   - data schema — before the logic on top of it;
   - removing dead code — before decomposing the module;
   - architectural changes — before DEC and DRY in the same modules.
6. **Build groups.** Tasks within a group do not overlap in files, including shared change points (PROTOCOLS.md §3). Groups are ordered by dependencies and, within that order, by priority: Critical and High first.
7. **Wave completion criterion** — per the gates from PIPELINE.md plus the wave's specific conditions.

## Format of the wave section in `PLAN.md`

```text
## W<n> — <name>
Status: planning | fixes | gate | completed
Completion criterion: …

| Task | Findings | Summary | Files | Group | Depends on | Class | Effort | Status | Commit |
|---|---|---|---|---|---|---|---|---|---|
| W2-T01 | SEC-01, QR-04 | … | src/auth/*.ts | G1 | — | A | M | pending | — |

Conflicts and how they were resolved: …
Deferred (with reason): …
```

Task statuses: pending → in progress → merged → verified. Also possible: "blocked (why)" and "waiting for owner (D-NNN)".
