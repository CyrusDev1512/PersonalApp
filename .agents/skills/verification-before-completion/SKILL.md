---
name: verification-before-completion
description: Verify evidence before declaring an implementation or bug fix complete. Use at handoff of changed work, not for ordinary questions or read-only exploration.
---

# Verification before completion

KNJSC adaptation of Superpowers. Evidence must support the exact claim.
Repository policy and verification commands live in [AGENTS.md](../../../AGENTS.md).
Read its relevant section; do not reload every linked project document.

## Select the claim

1. Identify the behavior changed and the acceptance criteria in scope.
2. Separate implementation, automated tests, browser checks, and performance claims.
3. Choose the smallest meaningful check that can disprove each claim.
4. Inspect the changed code and existing checks before adding new checks.
5. Reuse current evidence if it covers the final code and environment.
6. Rerun when later edits, failures, or environment changes invalidate evidence.

## Collect evidence

- Run the selected command to completion and read its exit status and summary.
- Inspect failures, skipped tests, warnings that affect the claim, and partial output.
- A running process or successful command launch is not a successful result.
- A test that cannot start because of configuration is not a passing test.
- A screenshot proves only what is visible, not that a write persisted.
- A successful HTTP response does not prove keyboard or scrolling behavior.
- A static source review establishes implementation shape, not measured speed.
- Check the original symptom where the bug concerned user interaction.

## Match the check to the work

| Change or claim | Evidence to seek |
|---|---|
| Behavior fix | Relevant regression test and original failing path |
| UI interaction | Browser action and observable result |
| Data write | Persisted result and relevant failure behavior |
| Permission change | Allowed and denied server paths |
| Performance improvement | Comparable before/after measurements |
| Documentation or skill files | Content, links, metadata, and diff |

Use [evidence boundaries](references/evidence.md) only when the available evidence
is partial, comes from a previous run, or differs from the claimed environment.

## Review the final state

- Review the final diff and Git status against the authorized scope.
- Separate pre-existing changes from this task's changes.
- Do not reset or revert another task's work to create a clean test result.
- Check that test outcomes still correspond to the final files.
- State any remaining material limitation, rather than hiding it in a pass count.
- Do not broaden testing after sufficient checks pass without a new reason.

## Handoff

Report the change, its purpose, checks actually run, and important gaps.
Use exact results; do not invent counts, timings, token savings, or environments.
Distinguish these outcomes:

- Implemented and verified within the stated scope.
- Implemented, with named checks still unverified or blocked.
- Investigated only; no implementation performed.

Skill discovery and automatic selection need a subsequent Codex turn/session.
File installation alone does not prove either behavior.
Do not launch unrelated tests or tools merely to demonstrate use of this skill.

## Coordination

This skill checks the evidence produced by the work; it does not repeat TDD,
browser profiling, or load-test procedures. Load those only if the task needs them.
No mandatory delegation, commit, push, PR, or extra approval is introduced here.
