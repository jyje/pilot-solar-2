# Case 05 — Solar Open2 x Hermes Agent

[English](README.md) / [한국어](README-ko.md)

[← back to repo overview](../README.md) · Want to run this yourself?
See [`REPRODUCE.md`](REPRODUCE.md) for step-by-step local setup.

**Status:** Verified — the official Hermes Agent image completed a live
round trip to `solar-open2` through its built-in Upstage provider.

## Goal

Run [Hermes Agent](https://github.com/NousResearch/hermes-agent) directly
against Upstage's **Solar Open2** model with the official Docker image and no
protocol-converting proxy.

## Official-support finding

**The Hermes integration is official.** Hermes Agent v0.18.2 ships an
`upstage` provider in its official Docker image (`solar` is an alias). Its
bundled provider implementation explicitly handles the `solar-open*` model
family and routes it through Upstage's OpenAI-compatible API. No local plugin,
custom endpoint, LiteLLM proxy, or source patch is needed.

The complete model configuration is therefore:

```yaml
model:
  provider: upstage
  default: solar-open2
```

Authentication stays outside the YAML file in `UPSTAGE_API_KEY`. This keeps
the case on the provider path maintained and distributed by Hermes itself.

### Is `solar-open2` itself officially available?

There is an important distinction between **Hermes provider support** and
**Upstage model availability**:

- Hermes officially supports the Upstage provider and explicitly recognizes
  the Solar Open model family.
- Upstage's current public console examples use `solar-pro3`; they do not
  currently advertise `solar-open2` as the default public model.

Therefore this case does not claim that every new Upstage account can select
`solar-open2`. The authenticated round trip is the authority for whether the
model remains enabled on the account used by this repository. Cases 01–04
previously verified that account against `solar-open2`, and Case 05 confirmed
it again on 2026-07-20.

## Run

Export an Upstage development key, then run the verification script:

```bash
export UPSTAGE_API_KEY="..."
./scripts/verify.sh
```

The script uses the official Hermes Agent image pinned by digest, mounts an
ephemeral `/opt/data` directory containing [`config.yaml`](config.yaml), and
runs three checks:

1. the image reports a Hermes Agent version;
2. `hermes doctor` accepts the Upstage configuration; and
3. non-interactive `hermes chat` returns `hermes-ready` from `solar-open2`.

The agent's terminal backend is `local`, which means tool commands execute
inside the already isolated Hermes container. The host repository is not
mounted into the container during this verification.

## Manual invocation

The live request exercised by the script is equivalent to:

```bash
hermes chat \
  --provider upstage \
  --model solar-open2 \
  --query "Reply with exactly: hermes-ready" \
  --max-turns 2 \
  --quiet \
  --ignore-rules
```

The matching GitHub Actions workflow reuses the repository's existing
`UPSTAGE_API_KEY` secret.

## Verification result

Verified locally on 2026-07-20 with:

- Hermes Agent v0.18.2 (`2026.7.7.2`, upstream `59fdd41f`);
- the official `nousresearch/hermes-agent` image pinned by digest;
- Hermes's bundled `upstage` provider; and
- Upstage model ID `solar-open2`.

`hermes doctor` reported `Upstage Solar` connectivity as healthy, and the
non-interactive chat returned the expected live response:

```text
hermes-ready
```

## Sources

- [Hermes Agent CLI reference](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/reference/cli-commands.md)
- [Hermes Agent provider guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/integrations/providers.md)
- [Hermes Agent Docker guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/docker.md)
- [Upstage Chat with Reasoning example](https://console.upstage.ai/api-keys?api=chat-reasoning)
