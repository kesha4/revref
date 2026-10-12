# DEP — Dependencies and supply chain

Finding ID prefix: DEP. Use together with `prompts/common-rules.md`.

Review the project's dependencies. Find:
- packages with known vulnerabilities (use the ecosystem's audit tools), and assess whether the vulnerable code is reachable from the project;
- outdated packages, especially those a major version behind or out of support, including the runtime version;
- abandoned libraries: no releases for a long time, no response to issues, a single maintainer;
- unused dependencies and dependencies that duplicate each other (two libraries for the same task);
- heavy dependencies pulled in for one small function;
- a missing or out-of-sync lock file, unpinned versions, installation from unverified sources;
- licenses incompatible with the project;
- dependencies that end up in production although they are only needed for development.

For each finding: the risk, the recommended upgrade or replacement, expected breaking changes per the changelog, and the regression risk.

Group upgrades into independent batches that can be applied and verified separately — from the safest to the riskiest.
