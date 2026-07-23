# Case 06 — Solar Open 2 x Grok Build

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md) · Want to run this yourself?
See [`REPRODUCE.md`](REPRODUCE.md) for step-by-step local setup.

**Status:** Verified — [xAI's Grok Build](https://github.com/xai-org/grok-build)
CLI answers real prompts against Solar Open 2 as a custom model
provider; all three methods below pass in CI. Known limitation: its
built-in tool-calling hits the same Upstage streaming bug documented in
[Case 05's Finding 2](../05-langchain-openwiki-solar-open2/README.md#finding-2-solar-open-2-drops-the-tool_call-function-name-when-streaming),
with no client-side workaround available (Grok Build is closed-source).

## Goal

Determine whether xAI's new terminal coding agent, Grok Build (launched
May 2026), can run against **Solar Open 2** as its model, using Grok
Build's own documented "any custom model" mechanism rather than a
protocol bridge — and be honest about what does and doesn't work.

## How it works

Grok Build reads model definitions from `config.toml`, discovered at
`$GROK_HOME/config.toml` (or `~/.grok/config.toml` when `$GROK_HOME` is
unset):

```toml
[model.solar-open2]
model = "solar-open2"
base_url = "https://api.upstage.ai/v1/solar"
name = "Solar Open 2 (Upstage)"
env_key = "UPSTAGE_API_KEY"
api_backend = "chat_completions"

[models]
default = "solar-open2"
```

`api_backend = "chat_completions"` is the key line: unlike
[the Codex draft](../draft/codex-upstage-solar-open2/README.md), which
is hard-locked to the Responses API protocol, Grok Build lets a custom
model pick its wire protocol per entry (`chat_completions`, `responses`,
or `messages`) — so it speaks the same OpenAI-compatible Chat
Completions format Upstage actually publishes, no bridge needed.

## Finding: custom models only work in the *user-level* config

Grok Build discovers a project-local `.grok/config.toml` (confirmed via
`grok inspect`), but its own docs are explicit that
["project configs are limited to MCP servers, plugins, and permission rules, not full user configs"](https://docs.x.ai/build/settings) —
a `[model.X]` entry placed there is silently ignored. `grok models` and
a live `-p` prompt both kept reporting `unknown model id` until the
model was moved into a *user-level* `config.toml` instead.

**Workaround used:** since this case can't (and shouldn't) write into
the real `~/.grok`, [`scripts/verify.sh`](scripts/verify.sh) points the
`$GROK_HOME` environment variable at a throwaway temp directory holding
a generated `config.toml` for the duration of the run — the same
isolation pattern Case 02 uses for Hermes Agent's home directory, and
Case 03 uses for `CODEX_HOME`.

## Finding: tool-calling breaks, same root cause as Case 05

Asking Grok Build to read a local file with its built-in file tool
against `solar-open2` fails every time with:

```text
Internal error: {
  "message": "API error (status 400 Bad Request): invalid_request_error:
  Invalid function name: ''. Function names can only include
  alphanumeric characters (a-z, A-Z, 0-9), underscores (_), or hyphens
  (-), and should be no longer than 64 characters.",
  ...
}
```

That is the exact same signature as
[Case 05's Finding 2](../05-langchain-openwiki-solar-open2/README.md#finding-2-solar-open-2-drops-the-tool_call-function-name-when-streaming):
Upstage's streamed Chat Completions responses drop the tool call's
`function.name`, and the client then can't route the call anywhere.
Case 05 could work around it because `openwiki` is open source — a
small fork added an opt-in `OPENWIKI_DISABLE_STREAMING` flag. Grok Build
is a closed-source compiled binary with no equivalent flag exposed for
custom providers, so this stays a hard blocker here rather than
something this repo can patch around.

`scripts/verify.sh` still runs this check every time (so the finding
stays honest, and gets noticed if Upstage ever fixes the underlying
bug), but doesn't fail the script on it — only the three methods below
gate pass/fail.

## Three methods

### Method A — deterministic single-turn reply

```bash
grok -p "Reply with exactly: grok-solar-ready" -m solar-open2
```

A plain non-tool-using round trip through Grok Build's headless mode
(`-p`), checked for an exact string.

### Method B — reasoning-heavy prompt

```bash
grok -p "Explain step by step why the sum of the first 50 positive integers equals 1275. Show your reasoning." -m solar-open2
```

No tools involved, so this isn't affected by the streaming bug above —
just Solar Open 2's own reasoning, checked for the correct numeric
answer.

### Method C — a small coding task

```bash
grok -p "Write a Python function named is_prime(n) that returns True if n is a prime number and False otherwise. Include a brief docstring. Output only the code in a single fenced code block." -m solar-open2
```

Grok Build's actual reason for existing — writing code — kept to plain
text output only, so it isn't affected by the tool-calling bug either.
Checked for `def is_prime` in the response.

## Verified methods

| Method | Result |
| --- | --- |
| A — single-turn reply | `grok-solar-ready` |
| B — reasoning-heavy prompt | Correctly derived `1275` via both the Gauss formula and the pairing method (full ~700-char transcript in CI's own output) |
| C — coding task | A correct, working `is_prime(n)` implementation with docstring (full code in CI's own output) |
| Finding — tool-calling | Reproducibly fails: `Invalid function name: ''` (same bug as Case 05) |

See [Evidence run](#evidence-run) below for the real, unedited transcript.

## Verification

[`scripts/verify.sh`](scripts/verify.sh) runs `grok` headlessly against
Solar Open 2 three times (Methods A, B, and C, all gated) plus one
non-gated tool-use finding check. It exits non-zero only if Method A's
reply doesn't contain `grok-solar-ready`, Method B's answer doesn't
contain `1275`, or Method C's code doesn't contain `def is_prime`.

Run locally with `UPSTAGE_API_KEY` set and `grok` installed
(`curl -fsSL https://x.ai/cli/install.sh | bash`):

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

Runs in CI (manual dispatch, solar-open2 only) two ways: as a step in
[`verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml)
alongside every other case, and on its own via
[`verify-06-grok-build-solar-open2.yml`](../.github/workflows/verify-06-grok-build-solar-open2.yml) —
both reuse the same `UPSTAGE_API_KEY` repository secret and install
`grok` via its official installer.

## Evidence run

**Evidence run:** [`verify` job, 2026-07-23](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30018053983/job/89243180618),
via this case's own single-case workflow,
[`verify-06-grok-build-solar-open2.yml`](../.github/workflows/verify-06-grok-build-solar-open2.yml)
(or browse [every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-06-grok-build-solar-open2.yml)
for the latest). Real, unedited output — not hand-picked or edited:

**Method A**

> grok-solar-ready

**Method B**

> This is a classic math problem! Let me walk through why the sum of
> the first 50 positive integers (1 + 2 + 3 + ... + 50) equals 1275.
>
> ## Step 1: Understand the problem
>
> We're summing: **1 + 2 + 3 + ... + 48 + 49 + 50**
>
> There are 50 terms total, and this is an arithmetic sequence where
> each term increases by 1.
>
> ## Step 2: Use the proven formula
>
> The sum of the first **n** positive integers has a well-known formula
> (discovered by Gauss as a child):
>
> $$S = \frac{n(n+1)}{2}$$
>
> This formula can be proven by pairing numbers from opposite ends of
> the sequence.
>
> ## Step 3: Apply the formula with n = 50
>
> $$S = \frac{50(50+1)}{2}$$
> $$S = \frac{50 \times 51}{2}$$
> $$S = \frac{2550}{2}$$
> $$S = 1275$$
>
> ...(truncated)

**Method C**

> ```python
> def is_prime(n: int) -> bool:
>     """Return True if n is a prime number, False otherwise."""
>     if n < 2:
>         return False
>     if n == 2:
>         return True
>     if n % 2 == 0:
>         return False
>     for i in range(3, int(n**0.5) + 1, 2):
>         if n % i == 0:
>             return False
>     return True
> ```

**Finding check — tool-use (not gated)**

> Internal error: {
>   "message": "API error (status 400 Bad Request):
>   invalid_request_error: Invalid function name: ''. Function names can
>   only include alphanumeric characters (a-z, A-Z, 0-9), underscores
>   (_), or hyphens (-), and should be no longer than 64 characters.",
>   "http_status": 400, ...
> }

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
