---
name: python-lint
description: Lint, format, and type-check Python code with ruff and ty, then run pytest, before considering any Python change done. Use whenever Python source files are added or edited in a uv-managed project.
---

# Python Lint & Test

jyje's Python projects are uv-managed and require three checks to pass before a
change is considered finished: ruff (lint + format), ty (type check), and
pytest (tests). Skipping any one of them is not acceptable for a "done" change.

## Required dev dependencies

Every uv project that ships Python source must declare these as dev
dependencies (add once per project, not per change):

```bash
uv add --dev ruff ty pytest
```

This populates `[dependency-groups] dev = [...]` in `pyproject.toml`. Do not
substitute alternatives (e.g. mypy, black, flake8, unittest) — ruff replaces
lint+format, ty replaces mypy, pytest replaces unittest, and mixing tools
fragments config for no benefit.

## Steps

Run these in order after editing Python files, and again right before
declaring the task complete:

1. **Lint, with autofix**
   ```bash
   uv run ruff check --fix .
   ```
2. **Format**
   ```bash
   uv run ruff format .
   ```
3. **Type check**
   ```bash
   uv run ty check .
   ```
4. **Test**
   ```bash
   uv run pytest
   ```

All four must exit clean (`ruff`/`ty` report no remaining issues, `pytest`
reports no failures) before the change is done. If `ty` or `ruff` flag
something that can't be fixed immediately (e.g. a third-party stub gap),
say so explicitly rather than silently ignoring the finding — don't suppress
with blanket `# noqa` / `# type: ignore` unless the suppression targets the
exact rule and includes a short reason.

## Test coverage expectations ("appropriate pytest")

- New functions/modules with non-trivial logic get at least one test that
  exercises the golden path and one that exercises a realistic edge case
  (empty input, error path, boundary value) — not just a smoke test that
  imports the module.
- Tests live under `tests/`, named `test_*.py`, mirroring the source layout
  they cover.
- Don't write tests for trivial pass-through code (e.g. a one-line wrapper
  with no branching) — match effort to actual risk, per jyje's general
  no-superfluous-abstraction preference.

## Notes

- Run these commands from the uv project root (where `pyproject.toml` lives),
  not from a subdirectory — `uv run` resolves the project from there.
- If `ruff` or `ty` aren't yet in `pyproject.toml`'s dev group, add them
  first (see above) rather than invoking a global/ad-hoc install.
