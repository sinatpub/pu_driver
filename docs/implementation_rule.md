# Implementation Rules

## Source of Truth

- `roadmap.md` defines the overall implementation scope.
- `implementation_progress.md` defines the current execution state.

## Execution

1. Always read both files before starting work.
2. Find the first incomplete task `[ ]`.
3. Mark it `[>]` before implementation.
4. Inspect the existing code before modifying it.
5. Follow the existing GetX architecture.
6. Do not rewrite unrelated modules.
7. Run analyzer/tests after implementation.
8. Fix implementation issues before moving forward.
9. Mark the task `[x]` only when verification passes.
10. Immediately continue to the next `[ ]` task.
11. Do not stop after completing one task unless:
   - blocked by missing information,
   - a critical architectural decision is required,
   - tests cannot be fixed safely,
   - or the user explicitly asks to stop.

## Progress Updates

After each completed task, update:

- status
- implementation summary
- files changed
- verification result
- blockers, if any
