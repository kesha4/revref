# DRY — DRY

Finding ID prefix: DRY. Use together with `prompts/common-rules.md`.

Review the codebase with a strict focus on DRY. Find:
- duplicated logic and repeated branching;
- copied types, schemas, constants, magic numbers and strings;
- rules duplicated across layers: client and server validation, permission checks, formatting, mappings;
- repeated configurations, data queries, error handling;
- diverged copies: code was copied, and then the copies started to differ. This is often a hidden bug — put such findings in a separate group and work out which version is correct.

Counterweight:
- Do not merge accidental similarity. Merging is justified if the fragments share one reason to change; similar code with different reasons to change is not duplication.
- Follow the rule of three. The wrong abstraction is worse than duplication.
- Duplication in tests is acceptable if it improves readability.

For each finding: all places of duplication; where and under what name to extract the common part; what the call will look like; the order of a safe refactoring with minimal regression risk.
