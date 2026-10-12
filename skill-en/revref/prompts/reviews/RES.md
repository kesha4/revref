# RES — Resilience

Finding ID prefix: RES. Use together with `prompts/common-rules.md`.

Review resilience to failures. Check:
- the error handling strategy: is it consistent; where errors are caught, where they are propagated, what the user ultimately sees; are there places where an error is lost or masked;
- timeouts: do all external calls (DB, HTTP, queues, file operations) have them, and are the values reasonable;
- retries: with exponential backoff and jitter, only for idempotent operations, with a limited number of attempts;
- protection against cascading failures: circuit breaker, bulkhead, graceful degradation when secondary dependencies are unavailable;
- lifecycle: graceful shutdown (finishing active requests and tasks), recovery after restart, incomplete operations after a crash;
- concurrency: races under concurrent requests, locks, redelivery and reprocessing of messages and background jobs, idempotency of handlers;
- resource limits: unbounded queues and buffers, unlimited parallelism, overload protection (backpressure).

For each finding, describe the failure scenario (what failed → what will happen to the system and the user) and propose a protection.
