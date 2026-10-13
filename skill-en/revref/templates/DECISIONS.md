# RevRef run decisions

A log of decisions the agent made autonomously, and a queue of decisions that require review or approval by the owner. Classes and labels — `POLICY.md`.

**How to answer (for the owner).** Find the decision by ID and fill in the "Owner decision" field:
- `ok` — accept the agent's recommendation;
- `confirm`;
- `reject`;
- `otherwise: <your instruction>`;
- a free-form question.

You can also answer without opening the file: `/revref ask` shows the highest-priority question in the chat (`/revref ask 5` — five, `/revref ask all` — all), and you can answer right there, e.g. `D-012 ok` (accept the recommendation) or `D-012 b`. The command can be entered while agents are working.

The agent will process the answer at the next step boundary or on the `/revref decisions` command. The agent will roll back rejected decisions together with their dependent changes.

## Approval queue

<!-- Synced by the orchestrator. 🔴 C first, then 🟠 B; within each — by impact. -->

| ID | Type | Class | Labels | Summary | Agent's recommendation | Blocks | Implementation | What happens if not decided |
|---|---|---|---|---|---|---|---|---|

## Decision log

<!-- New entries go at the end. Entry template:

### D-NNN · decision | question · 🟠 B · BEHAVIOR, UX · waiting for approval
- When and where: YYYY-MM-DD HH:MM · W<n> · task W<n>-T<nn> · findings: …
- Context: what was discovered and why a decision was needed
- Decision: what was done or is proposed
- Alternatives: what options there were and why they were rejected
- Options for the owner: a) … — recommended, because …; b) …; c) … (a recommendation is mandatory; if there is none — "Recommendation: none — <why and what needs to be known>")
- Blocks: tasks and findings waiting for this answer
- Linked decisions: D-NNN (together | depends on | blocks) — `/revref ask` uses them to show decisions as a group
- Rationale: why this option was chosen
- Impact: what will change, for whom (users, external systems, money, data)
- Affected legitimate scenarios: what an honest user will no longer be able to do or will get differently (per the fix check), or "none"
- Reversibility: how to roll back (git revert <hash> / do not merge the branch / migration down / flag)
- Implementation: commit <hash> | branch revref/pending/D-NNN | not implemented
- Dependent changes: what is built on top of this decision (rolled back together with it)
- How the owner can verify: verification steps
- Owner decision:
- Agent reply:

Type "question" — information is needed from the owner (for "needs information" findings, questions from reports): the "Decision", "Reversibility" and "Implementation" fields may be omitted, the class is optional.
Statuses: accepted (for 🟢 A) · waiting for approval · approved · rejected, reverted <hash> · replaced by owner instruction → D-NNN · answered (for questions)
Marks: skipped by owner <date> · answered in chat <date> · answer from INBOX <date>
-->
