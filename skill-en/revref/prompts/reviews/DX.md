# DX — Build, CI/CD and developer experience

Finding ID prefix: DX. Use together with `prompts/common-rules.md`.

Review the development and delivery infrastructure. Check:
- onboarding: can the project be set up from scratch per the README with one or two commands; how many non-obvious manual steps are there (try to go through them if possible);
- build reproducibility: are runtime and tool versions pinned, lock files, containerization; does the project build the same way locally and in CI;
- quality tools: linter, formatter, type checking, pre-commit hooks; are their settings consistent with each other and with CI;
- CI: what is checked (tests, lint, types, build, audit), what is missing, how long a run takes, is there caching;
- configuration and secrets for different environments: how they are set, where they are stored, is there a template (.env.example), is the configuration validated at startup;
- deployment: is it automated, is there a clear rollback process, migrations as part of deployment, separation of environments;
- everyday tasks: are there scripts for common operations (start, tests, DB reset, code generation), and are they documented.

Rank improvements by time saved for the team and reduced risk of breakage on deployment.
