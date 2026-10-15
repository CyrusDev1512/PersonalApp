# Evidence boundaries

Read this only when deciding how narrowly to phrase a result.

- Earlier output is usable when the relevant code, inputs, environment, and command
  have not changed. Identify its origin; do not describe historical data as a new run.
- A passing targeted suite supports its covered behavior, not the entire application.
- A browser test skipped for missing Chromium remains unverified.
- An HTTP latency test excludes layout, paint, typing latency, and scrolling smoothness.
- A response body size must say whether it is raw or compressed, and which response
  it includes. Do not compare HTML plus assets against a JSON fragment as equivalent.
- When no trace tool is available, report source/network observations separately
  from unmeasured frontend performance. Do not fabricate a trace or FPS value.
- For this skill pack, metadata validation is static evidence. Real skill discovery
  and routing are separate checks to perform in subsequent work.
