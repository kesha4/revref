# Security policy

RevRef runs autonomous agents with access to a real repository. The kit itself includes a guard hook, installers and an update mechanism, so security reports are taken seriously.

## Supported versions

The latest `3.x` release is supported. Older versions receive best-effort fixes only.

## Reporting a vulnerability

**Do not open a public issue.**

Email: **kesha4elovek@gmail.com**

Subject: `[security] RevRef <short title>`

Please include:

- kit version (`skill/revref/VERSION` or the release tag);
- platform: Claude Code / DSH, OS and shell;
- a minimal reproduction (commands, files, prompt or config);
- impact: what an attacker or a mistaken agent could achieve;
- whether the issue is already public anywhere.

You will get an acknowledgement on a best-effort basis, usually within a few business days. Fix timing depends on severity and on whether the issue affects a run in progress. Please give the project reasonable time to release a fix before public disclosure.

## In scope

- guard hook (`hooks/guard.sh`, `hooks/guard.ps1`) and ways to bypass it;
- installers and the update mechanism (`install.sh`, `install.ps1`, `bin/update.sh`), including source/verification of releases;
- handling of secrets in reports, commits, state files and prompts;
- prompt-injection guidance: whether project content can make the agent violate policy;
- unsafe defaults in the protocol that could damage a user's repository.

## Out of scope

- vulnerabilities in the projects RevRef reviews — report those to their maintainers;
- the model provider's own service, account, billing or regional access;
- social engineering of the owner;
- denial of service by intentionally huge inputs without a security impact.

## Safe harbour

Good-faith research is welcome. Do not exfiltrate data, do not attack systems you do not own, and do not publish details before a fix is available. If in doubt, ask first at the address above.
