# Case 07 — Solar Open 2 x Hermes Agent Helm

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md) · Want to run this yourself?
See [`REPRODUCE.md`](REPRODUCE.md) for step-by-step local setup.

**Status:** Verified — the community
[jyje/hermes-agent-helm](https://github.com/jyje/hermes-agent-helm) chart
deploys Hermes Agent onto a real (ephemeral) Kubernetes cluster and
completes a live round trip against Solar Open 2, both via the chart's own
built-in test Job and directly against the running gateway pod.

## Goal

Case 02 already proved Hermes Agent's official Docker image reaches Solar
Open 2 through its built-in Upstage provider. This case goes one step
further: does that same provider path still work once Hermes Agent is
deployed the way a real operator would run it long-term — as a Kubernetes
workload, installed from a published Helm chart, on an ephemeral **kind**
cluster — rather than a single `docker run`?

## How it works

[`values-solar-open2.yaml`](values-solar-open2.yaml) mirrors
`hermes-agent-helm`'s own
[`values-upstage.yaml`](https://github.com/jyje/hermes-agent-helm/blob/v0.12.0/charts/hermes-agent/values-upstage.yaml)
example, with the model swapped from the hosted `solar-pro3` default to the
open-weight `solar-open2` (same `upstage` provider, no other change
needed — that file's own comment already points here):

```yaml
config:
  model:
    provider: upstage
    default: solar-open2
  terminal:
    backend: local

env:
  UPSTAGE_API_KEY: "DUMMY_replace_me_0000000000000000000000" # overridden at install time
  OPENAI_API_KEY: "unused"

tests:
  chat:
    enabled: true
    prompt: "Reply with exactly: hermes-k8s-ready"
    maxTurns: 2
    failOnError: true
```

[`scripts/verify.sh`](scripts/verify.sh) creates a throwaway kind cluster,
installs the chart from its published OCI artifact
(`oci://ghcr.io/jyje/hermes-agent-helm/hermes-agent`, pinned to a tested
version) with this values file plus the real `UPSTAGE_API_KEY`, and deletes
the cluster again on exit — the same disposable-environment pattern every
other case in this repo already uses (a temp `GROK_HOME`/`CODEX_HOME`/Hermes
home directory), just at cluster scope instead of directory scope.

**Scope note:** the gateway container's default entrypoint
(`hermes gateway run`) is built around eventually bridging to a messenger
(Telegram, Discord, ...), but this case verifies the deployment itself, not
a messenger integration — both methods below run against the gateway pod
directly (the chart's own test Job, and `kubectl exec`). See
[Going further](#going-further-connecting-a-messenger) for how to add one
without changing anything this case verifies.

## Three methods

### Method A — the chart's own declarative chat test

`tests.chat.enabled=true` in the values file above turns on the chart's
built-in Helm-test Job: it runs `hermes chat` with the configured prompt
and fails the Job if the response doesn't match, entirely inside the
cluster. `scripts/verify.sh` renders that test hook and polls its Job
status directly (`helm test`'s own wait can stall on a CI runner — the same
reason `hermes-agent-helm`'s own CI does this), then checks the Job's logs
for the exact string.

### Method B — a live round trip against the running pod

```bash
kubectl exec -n hermes-agent "$pod" -- \
  hermes chat --provider upstage --model solar-open2 \
  --query "Explain step by step why the sum of the first 50 positive integers equals 1275. Show your reasoning." \
  --max-turns 2 --quiet --ignore-rules
```

The same reasoning-heavy prompt Case 06 uses, checked for the correct
numeric answer — this proves the *deployed pod itself* can converse with
Solar Open 2 (not just the one-shot test Job), the way an operator would
actually check a running release with `kubectl exec` or `helm test`.

### Method C — Hermes, in its own words, on the synergy

```bash
kubectl exec -n hermes-agent "$pod" -- \
  hermes chat --provider upstage --model solar-open2 \
  --query "You are Hermes Agent, currently running on Upstage Solar Open 2 as your backend model. In your own words, describe the specific strengths this model gives you as an agent -- think about reasoning, tool use, and coding ability. Be concrete and thorough." \
  --max-turns 2 --quiet --ignore-rules
```

Methods A and B check *that* Solar Open 2 answers correctly through this
deployment. Method C asks something different: let Hermes Agent itself,
running on Solar Open 2, describe what it thinks the model is good for as
an agent backbone — not a canned marketing description, a live model
response. Gated loosely (at least 10 non-empty lines, since the point is
a real, substantive answer rather than an exact string), and captured in
full rather than truncated. See [In its own words](#in-its-own-words-hermes-on-the-solar-open-2-synergy)
below for the real answer.

## Verified methods

| Method | Result |
| --- | --- |
| A — chart's own `tests.chat` Helm-test Job | `hermes-k8s-ready`, plus a full `hermes doctor` report confirming the seeded config and provider |
| B — live `kubectl exec` reasoning round trip | Correctly derived `1275` via the Gauss formula, reasoning printed by the running gateway pod itself |
| C — self-reflection on the Solar Open 2 synergy | 76 non-empty lines describing concrete strengths across reasoning, tool use, and coding ability — see below |

See [Evidence run](#evidence-run) below for the real, unedited transcript.

## Verification

[`scripts/verify.sh`](scripts/verify.sh) requires `docker` (daemon
running), `kind`, `kubectl`, and `helm` on `PATH`, plus `UPSTAGE_API_KEY`
set. It owns the full kind cluster lifecycle itself, so it runs identically
locally and in CI:

```bash
UPSTAGE_API_KEY="..." ./scripts/verify.sh
```

Runs in CI (manual dispatch, `solar-open2` only) two ways: as a step in
[`verify-all-sequential.yml`](../.github/workflows/verify-all-sequential.yml)
alongside every other case, and on its own via
[`verify-07-hermes-agent-helm-solar-open2.yml`](../.github/workflows/verify-07-hermes-agent-helm-solar-open2.yml) —
both reuse the same `UPSTAGE_API_KEY` repository secret and install
`kind`/`kubectl`/`helm` before the script runs.

## In its own words: Hermes on the Solar Open 2 synergy

Method C's real answer, unedited (76 non-empty lines total), from the CI
[Evidence run](#evidence-run) below:

> Running on **Solar Open 2** (Upstage's flagship open model with a
> 2026-02 knowledge cutoff) gives me several concrete strengths as an
> agent:
>
> ### Reasoning & Multi-Step Problem Solving
>
> Solar Open 2 is built on a strong reasoning backbone, which means I
> can chain logical steps together reliably — critical for agentic
> workflows where a single task decomposes into 5-10 tool calls with
> dependencies. When I'm debugging, I can hold the full state of an
> investigation in mind across turns: "I read the file, found the bug at
> line 42, traced it to the helper function, now need to check the
> tests." The model maintains coherence across these steps without
> losing context, which is essential when I'm not just answering
> questions but executing a plan.
>
> ### Tool Use & Instruction Following
>
> The model has been trained with disciplined instruction-following
> that translates directly to reliable tool invocation. I can:
>
> - **Read the available tools and pick the right one** — I don't just
>   call tools randomly; I reason about whether I need `search_files` vs
>   `read_file` vs `terminal` based on what I'm trying to accomplish.
> - **Parse structured tool output** — tool results come back in
>   structured formats (JSON, diffs, paginated file reads, terminal
>   stdout). Solar Open 2 handles these well without hallucinating
>   fields or misinterpreting output shapes.
> - **Chain tool calls correctly** — when a terminal command fails, I
>   can inspect the exit code, read the output, form a hypothesis, and
>   try a different approach — all within the same session.
>
> ### Coding Ability
>
> Upstage has emphasized coding in Solar's training, and that shows in
> several ways:
>
> - **Code synthesis with awareness of the existing codebase** — I can
>   search for imports, patterns, and symbols before writing new code,
>   so what I generate fits the project's conventions rather than being
>   generic.
> - **Targeted patching** — I can locate a specific function at a
>   specific line, read surrounding context, and apply a surgical edit
>   without dragging in a whole-file rewrite.
> - **Test-driven validation** — after making changes, I can run
>   `pytest`, `npm run check`, or custom test scripts and interpret the
>   results to verify correctness before marking something done.
>
> ### Long-Context Coherence
>
> Agentic work tends to be sprawling — file reads, web searches, browser
> interactions, subagent delegations. Solar Open 2 maintains context
> across these diverse modalities within a single session. I can switch
> from reading a Python file to navigating a web page to inspecting a
> JSON API response without losing what I was working toward.
>
> ### What This Means in Practice
>
> All of these strengths combine into what you're seeing right now: I
> can read your workspace, understand the project structure, load the
> right skills for the task, execute multi-step workflows (search, read,
> patch, test), and do it all with a clear understanding of *why* I'm
> doing each step and *what* I expect to happen next. The model isn't
> just generating text — it's generating text that represents a
> planning, tool-using agent that can verify its own work and
> course-correct when reality diverges from expectations.

Worth reading with a grain of salt — Hermes has its own framework
documentation in context, so some of what it describes about its own
tool set is things it knows about itself rather than things Solar Open 2
uniquely enables, and it can't fully verify its own self-assessment. But
as a real, live example of a model reflecting concretely on its own
operating characteristics rather than giving generic praise, it's a
good illustration of what this deployment can actually produce. The full
76-line answer (including a "Knowledge Currency" and "Korean Language
Proficiency" section not excerpted above) is in the raw CI log linked
below.

## Going further: connecting a messenger

This case stops at the gateway pod itself, deliberately — a messenger
round trip is a separate, additional thing to verify (`hermes-agent-helm`'s
own CI only live-verifies Discord today; Telegram is still a documented
placeholder there too). If you want to take this further yourself:

1. Create a bot with Telegram's [BotFather](https://core.telegram.org/bots#botfather)
   (`/newbot`, copy the token it gives you).
2. Adapt `hermes-agent-helm`'s
   [`values-openai-and-telegram.yaml`](https://github.com/jyje/hermes-agent-helm/blob/v0.12.0/charts/hermes-agent/values-openai-and-telegram.yaml)
   example — swap in this case's `upstage`/`solar-open2` model config, and
   set `env.TELEGRAM_BOT_TOKEN` to the token BotFather gave you.
3. `helm upgrade --install` with that combined values file instead of
   `values-solar-open2.yaml`.

Not something this case's `scripts/verify.sh` gates on — see
[`examples/argocd/hermes-agent-upstage.yaml`](https://github.com/jyje/hermes-agent-helm/blob/v0.12.0/examples/argocd/hermes-agent-upstage.yaml)
for a GitOps-style ArgoCD `Application` reference too (also not exercised
by this case; included as a pointer only).

## Evidence run

**Evidence run:** [`verify` job, 2026-07-23](https://github.com/jyje/pilot-upstage-solar-open2/actions/runs/30050614900/job/89351690459),
via this case's own single-case workflow,
[`verify-07-hermes-agent-helm-solar-open2.yml`](../.github/workflows/verify-07-hermes-agent-helm-solar-open2.yml)
(or browse [every run](https://github.com/jyje/pilot-upstage-solar-open2/actions/workflows/verify-07-hermes-agent-helm-solar-open2.yml)
for the latest). Real, unedited output — not hand-picked or edited:

**Method A**

> ```
> Hermes Agent v0.19.0 (2026.7.20) · upstream 3ef6bbd2
> Install directory: /opt/hermes
> Install method: docker
> Python: 3.13.5
> OpenAI SDK: 2.24.0
> [2/4] seeded config.yaml present in HERMES_HOME
>   OK: /opt/data/config.yaml
> ```

**Method B**

> ```
> ┌─ Reasoning ─────────────────────────────────────────────────────┐
> The user is asking me to explain step by step why the sum of the
> first 50 positive integers equals 1275. This is a mathematical
> explanation, not a coding or tool use task. Let me explain the
> reasoning clearly.
>
> There are multiple ways to explain this:
>
> 1. Using the formula for the sum of an arithmetic series
> 2. Using the pairing method (Gauss's method)
> 3. Using mathematical induction
> ```

**Method C**

> ```
> ✓ Hermes described its own Solar Open 2 strengths in 76 non-empty lines
> ```
>
> Full answer: [In its own words](#in-its-own-words-hermes-on-the-solar-open-2-synergy)
> above.

See the repo-level [`PLAN.md`](../PLAN.md) for full context.
