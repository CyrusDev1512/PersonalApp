---
name: test-driven-development
description: Use before implementing new behavior or fixing a behavioral bug that needs a regression test. Excludes ordinary questions, source exploration, and documentation-only edits.
---

# Test-driven development

KNJSC adaptation of Superpowers: establish the failing behavior before the fix.
Use [AGENTS.md](../../../AGENTS.md) for project rules, commands, and test environments.
Do not duplicate the project testing policy inside tests or this skill.

## Choose a useful regression

1. Read the affected code and its existing tests.
2. Identify the user's observable failure or intended new behavior.
3. Name the production mistake that would make the proposed test fail.
4. Choose the lowest test layer that exercises the actual failure.
5. Keep the setup small and consistent with existing fixtures.
6. Test outcomes rather than matching implementation text or private call order.

## Red

- Write a focused regression before changing the production behavior.
- Run that test and inspect the reason it fails.
- Missing dependencies, broken fixtures, and syntax errors do not establish red.
- If the test already passes, investigate whether it reaches the reported failure.
- Do not weaken a correct assertion to make the existing implementation pass.
- Record the meaningful failing result without dumping sensitive fixture data.

## Green

- Make the smallest production change that satisfies the intended behavior.
- Keep the fix within the authorized scope.
- Run the regression again and inspect its result.
- Check related behavior that the implementation could affect.
- Use real service/model behavior when it is practical.
- Mock external boundaries only where the test needs isolation.
- Do not add production branches that exist solely to satisfy a test mock.

## Refactor

- Once green, improve only structure needed by the change.
- Keep observable behavior unchanged during that cleanup.
- Rerun affected checks after the cleanup.
- Stop when the regression and relevant checks pass and no concern remains.
- Do not add broad scaffolding or one test for every trivial helper.

## Existing or concurrent changes

Never delete user code to enforce a test-first ritual.
If implementation already exists, disclose that the test was written afterward.
Establish regression sensitivity in an isolated comparison only when needed and safe.
Do not revert the shared checkout to reconstruct the failing state.
For behavior-preserving refactors, use meaningful existing coverage first.

Read [test design](references/test-design.md) only for choosing a layer,
handling mocks, or checking data and UI failure paths.

## Limits

- Documentation-only work needs content and link checks, not application TDD.
- Do not add tests that merely mirror a reversible cosmetic implementation.
- Reuse repository dependencies; this skill does not authorize installing a runner.
- Failure reproduction does not authorize changing business rules or permissions.
- If the test environment cannot run, state that red/green is unverified.
- Do not report manual observation as an automated test result.

## Handoff

Identify the regression, why it failed, and the final relevant results.
Verification at completion should reuse this evidence rather than rerun it by habit.
Follow the repository's reporting requirements for skipped or blocked checks.
