# Contributing

This repo hosts several independent agent-harness cases, all built around
Upstage's Solar Open2 model. See [`AGENTS.md`](AGENTS.md) for the full
directory structure and conventions, and [`PLAN.md`](PLAN.md) for the plan
and findings behind each case — this file focuses on conventions and the
commands you'll actually run.

## Conventions

- **Language**: all source code and code comments are English only. Every
  README (root and each case) ships an English original plus a Korean
  twin (`README-ko.md`); everything else — `AGENTS.md`, `PLAN.md`, this
  file — stays English-only. See `.claude/skills/centered-readme/SKILL.md`
  for the header format new READMEs should follow.
- **Commits**: gitmoji + `type(domain): title`, per
  `.claude/skills/git-commit-helper/SKILL.md`. Split unrelated concerns
  into separate commits. Commit messages and PR descriptions are English
  only.
- **Python changes** (Cases 02, 03): ruff (lint + format), `ty` (type
  check), and pytest all have to pass — see
  `.claude/skills/python-lint/SKILL.md` for the exact commands and test
  coverage expectations.
- **No mocked verification**: every case's `scripts/verify.sh` calls the
  real Upstage API. There's no offline/mocked test suite to fall back
  on — a working `UPSTAGE_API_KEY` is required to verify a change.

## Local development

Looking for a step-by-step walkthrough instead — exact prerequisites and
commands per case, with expected output and troubleshooting? See the
[Use Case Guide](docs/REPRODUCE.md) (English/Korean). The rest of this
section stays a quick reference for people already familiar with the
repo.

### Prerequisites

- `UPSTAGE_API_KEY` — every case's verification hits the real Upstage API.
- [`uv`](https://docs.astral.sh/uv/) — Cases 02 and 03 are uv-managed
  Python projects.
- Node 22+, the `claude` CLI (`npm install -g @anthropic-ai/claude-code`),
  and `claude-upstage` (`curl -fsSL https://console.upstage.ai/claude-upstage.sh | sh -s install`)
  — Cases 01 and 02 drive `claude` as a subprocess.
- `git` — Case 04 shallow-clones this repo into a gitignored `scratch/`
  directory rather than touching the real checkout.
- A patched `openwiki` build on `PATH` for Case 04: check out
  [`jyje/openwiki`](https://github.com/jyje/openwiki/tree/fix/disable-streaming-for-tool-calling-providers)
  at `fix/disable-streaming-for-tool-calling-providers`, then
  `pnpm install && pnpm run build && npm link` — the public npm release
  doesn't have the streaming fix Case 04 needs yet (see its README).
- Docker — Case 05 runs the official, digest-pinned `nousresearch/hermes-agent` image.

### Running one case

Each case's own script, straight:

```bash
UPSTAGE_API_KEY="..." ./01-solar-open2-harness/scripts/verify.sh
UPSTAGE_API_KEY="..." ./02-claude-agent-sdk-local/scripts/verify.sh
UPSTAGE_API_KEY="..." ./03-langchain-upstage-deepagents/scripts/verify.sh
UPSTAGE_API_KEY="..." ./04-langchain-openwiki-solar-open2/scripts/verify.sh
UPSTAGE_API_KEY="..." ./05-hermes-agent-solar-open2/scripts/verify.sh
```

Or through the shared, rate-limit-aware wrapper CI itself uses — waits for
a full Upstage budget reset before the case starts
(`scripts/wait-for-upstage-full-reset.sh`, 10-minute cap), so it's safe to
re-run repeatedly on a Tier-0 account without hand-tuning delays:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify-case.sh 01-solar-open2-harness solar-open2
```

### Running everything sequentially, like CI does

```bash
for case in \
  01-solar-open2-harness \
  02-claude-agent-sdk-local \
  03-langchain-upstage-deepagents \
  04-langchain-openwiki-solar-open2 \
  05-hermes-agent-solar-open2
do
  UPSTAGE_API_KEY="..." ./scripts/verify-case.sh "$case" solar-open2
done
```

Expect this to take a while on a Tier-0 account — see the root
[`README.md`](README.md)'s Tier 0 section for why.

### Python cases (02, 03)

```bash
cd 02-claude-agent-sdk-local  # or 03-langchain-upstage-deepagents
uv run ruff check --fix .
uv run ruff format .
uv run ty check .
uv run pytest
```

All four must pass before a Python change in either case is done.

### Linting shell scripts and workflows

```bash
shellcheck scripts/*.sh 0*/scripts/*.sh
actionlint .github/workflows/*.yml
```

## Adding a new case

1. Create `0N-<short-slug>/` at the top level, flat alongside the
   existing cases — no split between "core" and "special" cases.
2. Give it its own `README.md` + `README-ko.md` (centered header, per
   `.claude/skills/centered-readme/SKILL.md`), its own `REPRODUCE.md` +
   `REPRODUCE-ko.md` (step-by-step local setup, following the existing
   cases' pages as a template), and its own `scripts/verify.sh` that
   exercises the real Upstage API and exits non-zero on failure.
3. Wire it into
   [`.github/workflows/verify-all-sequential.yml`](.github/workflows/verify-all-sequential.yml)
   as one more `continue-on-error: true` step, invoked through
   `scripts/verify-case.sh` so it gets the same full-reset rate-limit
   wait as every other case.
4. Update `PLAN.md`'s summary table, the root `README.md`/`README-ko.md`
   Cases table, and `docs/REPRODUCE.md`/`docs/REPRODUCE-ko.md`'s use case
   guide table.

## Pull requests

CI (`verify-all-sequential.yml`) is manual-dispatch only and hits the real
Upstage API, so it isn't wired to run automatically on every PR. Note in
your PR description which case(s) you verified locally and how.
