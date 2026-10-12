# CMT — Code comments

Finding ID prefix: CMT. Use together with `prompts/common-rules.md`.

Review the comments in the code, including docstrings and public API descriptions. Do not assess external documents — there are separate reviews for them.

Find:
- comments that contradict the code — the most dangerous kind, severity raised;
- outdated comments describing former behavior, and historical notes in the style of "it used to be like this, now it is like that" — history belongs in version control;
- redundant comments that restate obvious code;
- confusing explanations, or ones that contradict each other or themselves;
- a mix of languages and commenting styles within the project.

The flip side — where a comment is missing:
- the non-obvious "why": the reason for a design choice, a workaround, a limitation of an external system;
- magic constants, complex algorithms and regular expressions;
- public API without a contract description: parameters, return value, errors, side effects.

Propose edits as a list by file: delete / rewrite (with the new text) / add (with the text). For comments to be deleted, state whether useful knowledge is lost and where to move it if it is needed.
