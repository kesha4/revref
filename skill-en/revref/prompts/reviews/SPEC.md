# SPEC — Compliance with the specification and technical docs

Finding ID prefix: SPEC. Use together with `prompts/common-rules.md`.

Review how well the implementation complies with the specification and the technical documentation: README, architecture and API documentation, configuration description, changelog. Act as an IT auditor and systems analyst. Do not assess user documentation (help, manual) — there is a separate review for it.

The project may have both code that deviates from the specification and a specification that lags behind the implemented functionality. If there is no specification, use the README and other project descriptions as the reference.

1. Traceability matrix: each requirement → where it is implemented (file, module) → status: implemented / partially / not implemented / contradicts / implemented beyond the specification (the functionality exists in the code but is not described).
2. Discrepancies: in each case, work out what is more correct to fix — the code or the documentation — and justify it. If it cannot be decided unambiguously, put the question in "Questions for the owner" with a recommendation.
3. Documentation quality: entries that do not match the logic; historical notes in the style of "it used to be like this, now it is like that"; confusing facts, or ones that contradict each other or themselves; the same information duplicated across different documents.
4. Whether the instructions work: the installation and startup steps from the README actually work (run them if possible); all environment variables, configuration parameters, API endpoints and commands are described and match the code.

Propose edits as a list by document and section: change / delete / add (with the text). For documentation blocks to be deleted, state whether needed information is lost.
