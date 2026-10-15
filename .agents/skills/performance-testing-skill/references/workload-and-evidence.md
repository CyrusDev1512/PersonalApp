# Workload and result design

- Baseline checks connectivity, meaningful responses, and artifact collection.
- Load tests validate the expected peak with realistic pacing.
- Endurance tests investigate degradation over time; use them only when that risk
  is in scope. Capacity/stress tests require a defined upper bound and stop rule.
- Mix reading, filtering, editing, and relevant import/export background activity.
  A script targeting a legacy table does not validate a new table automatically.
- Distinguish concurrent users, open tabs, in-flight requests, and requests/second.
- Measure write correctness as well as latency: competing edits, retries, rejected
  cells, and persisted outcomes must not disappear inside success counters.
- Keep expected permission/conflict rejections separate from failures and successful writes.
- Record sample counts and test duration; a tiny sample does not support stable p99 claims.
- Compare hardware, worker mode, database state, indexes, dataset, and warm-up window.
- If metrics come from a previous run, label their provenance and whether they match
  the current checkout. Never relabel historical evidence as a newly executed test.
- Use the existing project's commands and artifact conventions after inspecting them.
  This reference does not authorize executing seed scripts or changing runtime settings.
