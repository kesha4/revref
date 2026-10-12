# <ID> — <Review name>

Finding ID prefix: <ID>. Use together with `prompts/common-rules.md`.

<!--
A custom review for the project. Put the file in .revref/reviews/<ID>.md and specify the wave in CONFIG.md → "Custom reviews".
- ID: 2–8 uppercase Latin letters or digits, must not match the built-in ones (QR, SEC, BUG, …).
- Write it as an assignment for an expert: role, what to check, what to pay attention to, the format of review-specific tables.
- The common rules (finding format, scales, evidence, secrets) are included automatically — no need to repeat them.
- To extend a built-in review without replacing it, use a file .revref/reviews/<ID>.extra.md (e.g. SEC.extra.md with domain specifics).
-->

Review <what exactly>. Act as <expert role>.

Check:
- …;
- …;
- ….

For each finding: <what must be stated beyond the common format — e.g. a reference to a clause of a standard or a regulatory requirement>.
