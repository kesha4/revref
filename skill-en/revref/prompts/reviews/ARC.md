# ARC — Architecture

Finding ID prefix: ARC. Use together with `prompts/common-rules.md`.

Review the architecture. Start with a map: the main modules, their responsibilities and dependency directions (a mermaid diagram), the main data flows from entry to storage and back.

Assess:
- module boundaries, coupling and cohesion, adherence to Single Responsibility;
- dependency direction and layers: layer violations, circular dependencies, leaky abstractions;
- isolation of external systems (DB, third-party APIs, file system, queues): can they be replaced or substituted in tests;
- state and data flow management: where is the source of truth, and is there more than one;
- uniformity: are there two or more ways of doing the same thing (error handling, data access, configuration, validation);
- adherence to the conventions of the framework in use;
- readiness for known development plans (if described) — without designing "just in case".

Proportionality: assess the architecture relative to the project's scale and stage; do not propose patterns whose complexity will not pay off.

Rank improvements by impact-to-cost ratio. For large changes, give a sketch of the target state and an incremental migration path in which the project keeps working after every step.
