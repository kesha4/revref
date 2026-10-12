# API — API contracts

Finding ID prefix: API. Use together with `prompts/common-rules.md`.

Review API contracts — external (HTTP, gRPC, GraphQL, CLI, SDK) and internal ones between major modules or services. Check:
- consistency: naming, date and identifier formats, pagination, filtering, sorting, a single error format with codes and clear messages;
- semantics: methods and response codes, idempotency, behavior on a repeated request;
- backward compatibility: which changes have already broken or will break existing clients; is there versioning and a deprecation policy;
- contract description: is there a schema (OpenAPI, protobuf, JSON Schema), does it match actual behavior, are incoming and outgoing data validated against it;
- excess and insufficiency: extra fields that expose internals, or missing data that forces the client to make extra requests;
- limits: request size, rate, timeouts — are they set and documented.

For each finding, state which clients it affects and a way to fix it without breaking existing integrations.
