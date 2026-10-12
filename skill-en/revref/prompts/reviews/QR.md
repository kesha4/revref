# QR — Quick comprehensive review

Finding ID prefix: QR. Use together with `prompts/common-rules.md`.

In the pipeline this review runs twice: in wave W1 (Reconnaissance) and in wave W9 (delta).

Act as an experienced Senior Software Engineer, a demanding Product Manager and a skeptical Tech Lead. Conduct a tough but constructive comprehensive review of the project. I need weak spots, hidden risks and areas for growth, not compliments.

Start with a short summary: the project's purpose, target users, stack, key modules and entry points — as you understood them. If the project description diverges from what you see in the code, note it.

Go through the project block by block. If a block is not applicable (for example, there is no UI), say so in one line and move on to the next.

1. **Architecture and scalability:** critical design mistakes; bottlenecks as load, data volume and the team grow.
2. **Business logic and functionality:** how well the solution meets its stated goals; missed scenarios and functionality gaps.
3. **Errors and edge cases:** specific logic errors in the code and documentation; behavior on empty, invalid and extreme data and on failures of external systems.
4. **Security and reliability:** attack vectors, vulnerabilities, data leaks, risks of data loss or corruption, behavior under failures.
5. **Technical debt and code cleanliness:** violations of KISS, DRY, SOLID; what will get in the way of maintenance and further development.
6. **Performance:** what is slow or inefficient and how to optimize it.
7. **UX and interface:** usability, unnecessary steps, non-obvious places, stages where the user may get confused or give up; basic accessibility; are hints and help sufficient to figure things out without outside assistance.
8. **Tests, build and operations:** are there tests and CI, are build and startup reproducible, how are configuration, secrets and dependencies managed, are there backups.
9. **Stack and soundness of decisions:** are the chosen stack and approaches justified; what can be done simpler and faster without loss of quality.

At the end, in addition to the summary required by the common rules:

- **Maturity score** for each block on a 1–5 scale with a one-sentence justification.
- **Applicability matrix** of the specialized reviews — a table covering all IDs: HYG, BUG, DRY, DEC, ARC, EDGE, RES, DATA, SEC, DEP, PERF, OBS, DX, TEST, RWD, A11Y, API, I18N, CMT, SPEC, UDOC, plus the project's custom reviews from `.revref/reviews/`, if any. For each ID: "run" / "skip" / "narrow focus", the reason, and what to pay special attention to, linked to this review's findings.
- **Distribution of QR findings** across the specialized reviews — which review should receive each finding for in-depth examination.
- **Urgent:** findings that are dangerous to leave until their scheduled wave, with an explanation of why.

## Delta mode (W9)

If the task packet specifies delta mode:

- **Comparison.** Compare the current state with the W1 report (`.revref/reports/QR.md`) and the baseline in `CONTEXT.md`.
- **Maturity score.** Update the score for each block and show the change relative to W1.
- **Regressions.** Look primarily for refactoring regressions: inconsistencies between parts changed in different waves, broken non-obvious links, lost behavior, remnants of unfinished transitions (old and new way at the same time).
- **No repeats.** Do not repeat findings that are already in `FINDINGS.md` with the status "deferred" or "waiting for owner".

Delta mode report: `.revref/reports/QR-delta.md`.
