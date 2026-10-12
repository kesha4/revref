# DEC — Decomposition

Finding ID prefix: DEC. Use together with `prompts/common-rules.md`.

Review the decomposition of the code. Find:
- large files and modules with mixed responsibilities (guideline: more than 400–500 lines, adjusted for language and file type);
- overloaded functions (guideline: more than 50 lines), deep nesting (more than 3 levels), long if/else and switch chains;
- "god" classes and objects, long parameter lists, boolean flags that switch a function's behavior;
- mixed levels of abstraction in a single function: business rules interleaved with I/O, formatting, DB queries.

Guidelines are not rules. A large but cohesive file (a constants table, configuration, generated code) is not a problem. Do not split for the sake of splitting.

For each finding:
- the maintainability risk: what specifically will become hard;
- a split plan as a sequence of steps, each of which preserves behavior and is verified separately (extract → move → replace call sites → delete the old code);
- if the area is not covered by tests, the first step is characterization tests that pin down the current behavior.
