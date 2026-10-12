# BUG — Bugs and logic errors

Finding ID prefix: BUG. Use together with `prompts/common-rules.md`.

Review the codebase with a focus on bugs and logic errors — defects that already exist in the code and show up under realistic use. Look for:
- errors in conditions and branches, inverted logic, off-by-one;
- null/undefined/None dereferences, wrong assumptions about data shape and types;
- wrong order of operations, mutation of shared state, side effects in unexpected places;
- async and concurrency: missing await, unhandled promises and exceptions, races, deadlocks;
- resource leaks: unclosed files, connections, subscriptions, timers;
- silently swallowed errors and lost exception context;
- dates and times: time zones, daylight saving time transitions, formats;
- arithmetic: float for money, overflow, division by zero, rounding;
- encodings and string comparison, wrong cache invalidation, non-idempotent repeated operations.

For each finding, you must provide:
- a reproduction scenario: input data or sequence of actions → wrong result;
- a regression test that will catch this bug.

Do not include: style and potential improvements (these are not bugs); missing protection against exotic inputs (that is the edge cases review); vulnerabilities that require attacker action (that is the security review).
