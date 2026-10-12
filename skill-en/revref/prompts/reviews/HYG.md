# HYG — Code hygiene

Finding ID prefix: HYG. Use together with `prompts/common-rules.md`.

Review code hygiene. Find:
- dead code: unused functions, classes, exports, files, unreachable branches;
- unused imports, variables, parameters;
- unused dependencies in manifests, as well as assets, scripts, environment variables and configuration keys;
- commented-out code, debug output (console.log, print, dump), temporary hacks and stubs;
- stale TODO/FIXME/HACK: already done, no longer meaningful, or without a clear next step;
- feature flags that are permanently on or off;
- trivial wrappers that add nothing;
- misleading names: the name promises one thing, and the code does another.

Before declaring code dead, check for implicit usage: reflection, calls by string name, convention-based routing and DI, templates, configs, build scripts, tests, public API for external consumers. Use the ecosystem's analyzers if available (for example, knip, ts-prune, vulture, deadcode, staticcheck).

Split findings into two groups:
1) Safe to delete now — with a minimal patch for each finding.
2) Needs a decision — what exactly is unclear and how to check it.
