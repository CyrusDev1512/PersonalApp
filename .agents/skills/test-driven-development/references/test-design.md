# Focused regression design

- For parsing and calculation, use deterministic input/output cases in existing
  service tests. Include a boundary that previously failed, not a generic example.
- For persistence, exercise the write and read back the stored outcome.
- For endpoint permissions, cover the allowed path and direct forbidden access.
- For browser bugs, a server-only assertion may miss focus, selection, or a hidden
  error message. Use existing browser test facilities for that specific interaction.
- For concurrency, two sequential writes cannot prove simultaneous writes are safe.
  Use the repository's transactional/concurrency facilities when concurrency is in scope.
- A mock should isolate an external dependency, not replace the behavior under test.
- Assertions about a mock's call count alone rarely establish a business outcome.
- Use fixed, synthetic data and existing test isolation; do not test writes on live data.
- Property-based testing is deferred in this pack. Do not install a generator merely
  because this reference mentions input combinations.
