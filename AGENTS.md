# pilot-upstage-solar-open2

Portfolio/seminar repo hosting several independent agent-harness use cases
built around Upstage's Solar Open2 model and the Claude Code / OpenAI
Codex / LangChain / Hermes Agent ecosystem. See [`PLAN.md`](PLAN.md) for the full plan and [`README.md`](README.md)
for the public-facing overview.

## Structure

```
pilot-upstage-solar-open2/
├── .claude/skills/                    # skills available in this repo (see below)
├── PLAN.md                            # full plan (all cases)
├── README.md / README-ko.md           # portfolio front page
├── 01-solar-open2-harness/            # Case 01: Claude Code harness on Solar Open2
├── 02-claude-agent-sdk-local/         # Case 02: local Claude Code via Claude Agent SDK
├── 03-langchain-upstage-deepagents/   # Case 03: deepagents init via LangChain Upstage SDK
├── 04-langchain-openwiki-solar-open2/ # Case 04: openwiki documents this repo via Solar Open2
└── 05-hermes-agent-solar-open2/       # Case 05: Hermes Agent via its built-in Upstage provider
```

Referred to as **Case 01 / Case 02 / ...** in prose and docs — the
numbered directory prefixes are just filesystem sort order, not a rename
target. All cases live at the top level as one flat list — no split
between "core" and "special" cases.
Each case directory is a self-contained experiment with its own `src/`
(uv-managed, or a Node project for Case 04), or a Docker-based runnable
configuration for Case 05. All are implemented and verified. Each has its
own `scripts/verify.sh`; all 5 are run, solar-open2 only, as steps in the
single `.github/workflows/verify-all-sequential.yml` workflow (manual
`workflow_dispatch`), which reuses the same `UPSTAGE_API_KEY` secret.
Case 03 pins Python 3.13 instead of 3.14 (the default elsewhere) — see
its README for why.

## Skills available

- `centered-readme` — format README headers as a centered hero block
- `git-commit-helper` — gitmoji + conventional-commit-ish commit message policy
- `python-lint` — ruff + ty + pytest workflow, required for any Python change

## Conventions

- **Language**: all source code and code comments are English only — no
  Korean in code, docstrings, or inline comments.
- **README language**: English is the default for every README's primary
  content. Every scenario — the repo root and every case directory —
  gets a Korean twin (`README-ko.md`) with the same language navigator
  style. Everything else (source code, comments, `AGENTS.md`, `PLAN.md`)
  stays English-only.
- **Python changes**: run the `python-lint` skill's workflow (ruff check,
  ruff format, ty check, pytest) before considering a Python change done.
- **Commits**: follow the `git-commit-helper` skill's gitmoji + type/domain
  format. Never commit or push without explicit user approval.
