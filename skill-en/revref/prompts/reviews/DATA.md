# DATA — Data, databases and migrations

Finding ID prefix: DATA. Use together with `prompts/common-rules.md`.

Review how the project works with data. Check:
- how well the schema matches the domain: entities, relationships, normalization, naming;
- integrity constraints (NOT NULL, UNIQUE, FK, CHECK) where currently only application code enforces them;
- indexes for actual queries: missing, redundant, unused;
- transaction boundaries and isolation levels: operations that must be atomic but are not;
- migrations: reversibility, safety on a non-empty DB (locks, long ALTERs, index rebuilds), the "code ↔ schema" deployment order, compatibility of the old code version with the new schema during deployment;
- storage of money, dates and time zones, enums, JSON fields;
- data lifecycle: soft delete, archiving, deletion of personal data, unboundedly growing tables;
- backups: do they exist, has restoring been tested, what amount of data loss is acceptable.

For each finding, give a scenario of data corruption, loss or inconsistency and a safe fix plan, including migration of existing data.
