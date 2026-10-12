# PERF — Performance

Finding ID prefix: PERF. Use together with `prompts/common-rules.md`.

Review performance with a focus on real bottlenecks, not micro-optimizations. Check:
- algorithmic complexity on hot paths, nested loops over large collections;
- database access: N+1, missing indexes for actual queries, queries without pagination and limits, unnecessary fields and joins;
- network and I/O: blocking calls, sequential requests that could run in parallel, missing caching and batching;
- memory: allocations on hot paths, leaks, unboundedly growing caches and collections;
- concurrency: connection and thread pools, locks, resource contention;
- frontend: bundle size, lazy loading, unnecessary re-renders and recalculations, heavy images and fonts, Core Web Vitals;
- application startup and cold start time.

For each finding, state:
- at what load or data volume the problem becomes noticeable;
- how to measure the current state (profiler, benchmark, EXPLAIN, Lighthouse);
- the expected gain after the fix.

If there are no bottlenecks at the current scale, say so and state what will become the first bottleneck as the project grows.
