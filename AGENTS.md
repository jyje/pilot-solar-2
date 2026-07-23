# pilot-upstage-solar-open2

A repo hosting several independent agent-harness use cases built around
Upstage's Solar Open 2 model and the Claude Code / OpenAI Codex /
LangChain / Hermes Agent ecosystem. See [`PLAN.md`](PLAN.md) for the full plan and [`README.md`](README.md)
for the public-facing overview.

## Structure

```
pilot-upstage-solar-open2/
├── .claude/skills/                    # skills available in this repo (see below)
├── PLAN.md                            # full plan (all cases)
├── README.md / README-ko.md           # repo front page
├── CONTRIBUTING.md                    # conventions + local dev commands
├── 01-solar-open2-harness/            # Case 01: Claude Code harness on Solar Open 2
├── 02-hermes-agent-solar-open2/       # Case 02: Hermes Agent via its built-in Upstage provider
├── 03-claude-agent-sdk-local/         # Case 03: local Claude Code via Claude Agent SDK
├── 04-langchain-upstage-deepagents/   # Case 04: deepagents init via LangChain Upstage SDK
└── 05-langchain-openwiki-solar-open2/ # Case 05: openwiki documents this repo via Solar Open 2
```

Referred to as **Case 01 / Case 02 / ...** in prose and docs — the
numbered directory prefixes are just filesystem sort order, not a rename
target. All cases live at the top level as one flat list, with no split
between "core" and "special" cases.

Each case directory is a self-contained experiment with its own `src/`
(uv-managed, or a Node project for Case 05), or a Docker-based runnable
configuration for Case 02. All are implemented and verified.

Each has its own `scripts/verify.sh`. All 5 run, solar-open2 only, as
steps in the single `.github/workflows/verify-all-sequential.yml`
workflow (manual `workflow_dispatch`), which reuses the same
`UPSTAGE_API_KEY` secret. Cases 03 and 04 (the two `uv`-managed Python
cases) both pin Python 3.13 — Case 04 requires it (`tokenizers` has no
`cp314` wheel yet); Case 03 matches it for consistency, see Case 04's
README for the underlying finding.

## Solar Open 2 naming reference

Several distinct strings all point at the same model. Mixing them up has
already broken URLs and doc prose more than once — treat each one as
fixed, not interchangeable:

| Context | Exact string | Where it's used |
| --- | --- | --- |
| Prose / headings | `Solar Open 2` (with space) | READMEs, PLAN.md, any human-readable text |
| API model slug | `solar-open2` (lowercase, no space) | `--model` flags, `SOLAR_MODEL`/`ANTHROPIC_MODEL` env vars, code |
| Hugging Face repo path | `upstage/Solar-Open2-250B` (no space, no extra hyphen) | `https://huggingface.co/upstage/Solar-Open2-250B` and its `/blob/main/...` subpaths |
| Shields.io badge slug | `solar--open2--250b` (double-dash escapes a literal dash) | badge URL parameter only, e.g. `img.shields.io/badge/...-upstage/solar--open2--250b-yellow` |
| Repo/case directory names | `solar-open2` (lowercase, no space) | e.g. `pilot-upstage-solar-open2`, `01-solar-open2-harness` |

Two exceptions worth knowing:
- Verbatim model output quoted in evidence sections (e.g. "Hello! I'm
  Solar Open2...") is quoted exactly as the model said it — don't "fix"
  the model's own self-reference to match the prose convention.
- `solar-pro3` is a *different* Upstage model, mentioned only for
  contrast (Tier 0 rate-limit comparisons, Upstage's own console
  examples) — no case in this repo defaults to it.

The Hugging Face URL specifically has broken twice already from careless
find/replace passes (a stray space, then a stray hyphen). After any script
or broad substitution touching "Solar Open" text, grep for `Solar-Open` in
`*.md` and confirm every match reads exactly `Solar-Open2-250B`.

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
  style. Everything else (source code, comments, `AGENTS.md`, `PLAN.md`,
  `CONTRIBUTING.md`) stays English-only.
- **Python changes**: run the `python-lint` skill's workflow (ruff check,
  ruff format, ty check, pytest) before considering a Python change done.
- **Commits**: follow the `git-commit-helper` skill's gitmoji + type/domain
  format. Never commit or push without explicit user approval.
