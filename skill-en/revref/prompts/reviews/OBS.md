# OBS — Observability

Finding ID prefix: OBS. Use together with `prompts/common-rules.md`.

Review observability: can you tell from the system's signals that it works correctly, and quickly find the cause if it does not.

Logging:
- are there enough logs on critical paths and at decision points;
- are errors logged with enough context for diagnosis (what was being done, with which parameters, for whom);
- structured logs; correct levels (an error is not written as info, routine events do not clutter warning); noisy logs that hide what matters;
- can the chain of events of a single request or operation be reconstructed (a correlation/trace ID across all components);
- are there no passwords, tokens, keys or personal data in logs; is there rotation and a size limit.

Metrics and health:
- key metrics: requests, errors, latency, resource saturation, important business events;
- health and readiness checks that verify real operability, not just that the process is alive;
- error collection and grouping (Sentry and similar), alerts on important failures without an avalanche of false positives;
- an audit log for security-relevant actions: login, permission changes, data deletion.

The bottom-line question: if something breaks right now, how and how soon will we find out, and how long will it take to find the cause?

Propose concrete points where logging, metrics and checks should be added or improved.
