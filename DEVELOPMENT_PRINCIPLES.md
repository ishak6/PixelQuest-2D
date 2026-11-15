# Core Engineering Skills

These principles apply to every Pixel Quest development task, from design through release.

## 1. Simplicity First
- Prefer the smallest clear solution that meets the requirement.
- Avoid unnecessary dependencies, abstractions, duplicated logic, and speculative features.
- Keep code readable and easy to maintain.
- Do not sacrifice correctness, accessibility, or reliability for fewer lines.

## 2. Surgical Changes
- Identify the exact root cause and the smallest set of files that must change.
- Preserve existing behavior outside the requested scope.
- Avoid broad rewrites when a focused patch is sufficient.
- Review the diff for unrelated edits and regressions before committing.

## 3. Think Before Coding
Before implementation:
1. Restate the goal and observable acceptance criteria.
2. Inspect the existing code, architecture, and dependencies.
3. Trace relevant input, state, signals, and lifecycle paths.
4. Consider edge cases, platform constraints, and likely failure modes.
5. Choose an implementation plan and tests.

Do not start coding while important requirements or dependencies remain unclear.

## 4. Goal-Driven Execution
- Tie every change to a stated project goal and acceptance criteria.
- Work in small, verifiable steps.
- Run the most relevant checks after each meaningful change.
- Fix failures before moving on; do not hide or bypass failing tests.
- Report exactly what changed, what checks passed or failed, and what remains unverified.

## Required delivery loop
**Understand → Inspect → Plan → Implement → Test → Review diff → Report**

A successful commit is not proof of a successful build. A successful build is not proof of correct runtime behavior. Device-specific behavior must be reported as unverified unless it was actually tested on a device.
