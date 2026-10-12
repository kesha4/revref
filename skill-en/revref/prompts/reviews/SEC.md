# SEC — Security

Finding ID prefix: SEC. Use together with `prompts/common-rules.md`.

Review security with an attacker's mindset.

Start with a brief threat model: what is valuable in the system (data, money, access), who can attack (an anonymous user, an authenticated user, someone on the same network, a person with access to the repository or server), what the entry points are.

Check:
- authentication: password storage, sessions and tokens (lifetime, revocation, client-side storage), account recovery, brute-force protection;
- authorization: permission checks on every action and object, IDOR, privilege escalation, client-side-only checks;
- injections: SQL/NoSQL, command, code, templates; path traversal; insecure deserialization; SSRF;
- web: XSS, CSRF, CORS, security headers, open redirect, file uploads;
- cryptography: outdated algorithms, hardcoded keys, home-grown implementations, quality of random value generation;
- secrets: in code, configs, git history, logs, error messages, the client bundle;
- insecure defaults, debug mode in production, disclosure of internal information;
- rate limiting and protection against resource exhaustion;
- vulnerable dependencies (run the ecosystem's audit tool; detailed analysis belongs to the dependencies review).

Take the project's domain into account: for example, for network services — protection of the protocol, keys and configuration; for payments — integrity and non-repeatability of operations.

For each vulnerability: a step-by-step exploitation scenario, what the attacker needs, the consequences, remediation measures. Mark vulnerabilities without a real exploitation path as hypotheses.
