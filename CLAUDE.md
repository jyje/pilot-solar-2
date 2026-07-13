# pilot-solar-2

Portfolio/seminar repo hosting three independent agent-harness experiments
built around Upstage's Solar Open2 model and the Claude/LangChain agent
ecosystem. See [`PLAN.md`](PLAN.md) for the full plan and [`README.md`](README.md)
for the public-facing overview.

## Structure

```
pilot-solar-2/
├── .claude/skills/                    # skills available in this repo (see below)
├── PLAN.md                            # full 3-topic plan
├── README.md / README-ko.md           # portfolio front page (only bilingual pair in this repo)
├── 01-solar-open2-harness/            # topic 1: Claude Code harness on Solar Open2
├── 02-claude-agent-sdk-local/         # topic 2: local Claude Code via Claude Agent SDK
└── 03-langchain-upstage-deepagents/   # topic 3: deepagents init via LangChain Upstage SDK
```

Each topic directory is a self-contained experiment. When implementation
starts on a topic, it gets its own `src/` (uv-managed) inside that directory.

## Skills available

- `centered-readme` — format README headers as a centered hero block
- `git-commit-helper` — gitmoji + conventional-commit-ish commit message policy
- `python-lint` — ruff + ty + pytest workflow, required for any Python change

## Conventions

- **Language**: all source code and code comments are English only — no
  Korean in code, docstrings, or inline comments.
- **README language**: English is the default for every README. Only the
  repo-root `README.md` gets a Korean twin (`README-ko.md`) with a language
  navigator; topic READMEs stay English-only.
- **Python changes**: run the `python-lint` skill's workflow (ruff check,
  ruff format, ty check, pytest) before considering a Python change done.
- **Commits**: follow the `git-commit-helper` skill's gitmoji + type/domain
  format. Never commit or push without explicit user approval.
