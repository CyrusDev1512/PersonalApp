---
name: performance-testing-skill
description: Plan, run, or analyze bounded load, concurrency, capacity, and endurance tests. Use for multi-user or large-data performance verification; excludes routine tests, browser-only lag, and ordinary implementation work.
---

# Performance testing

KNJSC adaptation of jovd83's performance-testing-skill.
Read [AGENTS.md](../../../AGENTS.md) for the authorized scope and current test policy.
Use existing Locust infrastructure and project thresholds rather than upstream defaults.

## Establish the test boundary

1. Inspect the current script, target URL, runtime mode, and dataset before execution.
2. Determine whether the request is planning, analysis, or authorization to generate load.
3. Reuse authorization already given; ask only for a missing consequential decision.
4. Confirm test isolation and the effects of setup and workload operations.
5. Do not seed, reset, migrate, or load-test active data merely to satisfy a benchmark.
6. If execution is not authorized, produce the plan or analyze existing results only.

## Model the actual workload

- Define users, pacing, duration, row/column count, and representative operations.
- Distinguish customer count from order/record count and multi-year growth.
- Use current product scope; do not import the old workload's formulas automatically.
- Cover the relevant user roles, filters, writes, and background work.
- Include simultaneous same-row edits when correctness under concurrency is in scope.
- Define stop conditions and acceptance thresholds before load generation.
- Retrieve thresholds from project sources instead of freezing them in this skill.

Read [workload and evidence](references/workload-and-evidence.md) only when
designing stages, comparing runs, or judging concurrency and failure results.

## Execute incrementally

- Run a short baseline first on the identified test environment.
- Check authentication, data availability, and result collection before increasing load.
- Stop on an incorrect target, broken setup, or the agreed abort conditions.
- Increase concurrency only to the authorized bound.
- Reuse Locust rather than install k6, JMeter, or a new runtime by default.
- Account for existing work on a shared machine that may distort timings.
- Do not restart services or change worker counts outside the authorized experiment.

## Collect and interpret

- Record latency distributions, throughput, errors, and relevant resource observations.
- Separate expected rejection from unexpected errors; report both counts.
- Do not call silent lost writes a successful run because HTTP returned 200.
- Record warm-up exclusions and the window used for percentiles.
- Keep the dataset, runtime, and scenario comparable for before/after claims.
- Use per-operation results where a global average hides slow writes or reads.
- HTTP load tests do not measure browser rendering or typing responsiveness.

## Evidence and reporting

- Save raw results in the repository's established artifact location when available.
- Report exact commands, environment, scenario, thresholds, and measured outcomes.
- Identify skipped operations, missing metrics, short runs, and untested scale.
- No token, capacity, or performance improvement is inferred from file installation.
- Do not copy credentials or customer records into artifacts.
- If runtime evidence is insufficient, report that rather than marking acceptance met.

## Coordination

Use web-perf only for a separate browser question and performance-optimization
when a measured bottleneck needs a design or code change.
Do not read all their references as part of a load-test task.
