# Case 05 — Use Case Guide

[English](REPRODUCE.md) / [한국어](REPRODUCE-ko.md)

[← back to this case's README](README.md) · [← all cases' use case guides](../docs/REPRODUCE.md)

Goal: run Hermes Agent's own bundled Upstage provider against Solar
Open2, through the official Docker image — no bridge, no proxy.

Full narrative, findings, and verified transcripts: [`README.md`](README.md).

Haven't set up `UPSTAGE_API_KEY` or read about the shared Tier-0 rate
limit yet? Start at [`docs/REPRODUCE.md`](../docs/REPRODUCE.md) first —
this page assumes both are already handled.

## What you need

- Docker, with the daemon running

That's it. No Node, no Python, no `openwiki`.

## Run it

From the repo root, `cd` into this directory first, then run its script:

```bash
cd 05-hermes-agent-solar-open2
export UPSTAGE_API_KEY="up_..."
./scripts/verify.sh
```

The first run pulls the digest-pinned `nousresearch/hermes-agent` image —
expect that one download the first time only.

## What success looks like

```
== Model under test: solar-open2 ==
...
hermes-ready
✓ Hermes completed a live solar-open2 round trip
```

## If something goes wrong

- **`Docker daemon is not available`** — start Docker Desktop (or your
  Docker service), then re-run.
- **Image pull is slow** — normal on the first run; the digest pin means
  every later run reuses the same cached layers.

## Try it by hand

Once the image is verified, this is the same call the script makes,
runnable directly for your own prompts. Hermes expects a whole
`/opt/data` directory, not a single mounted file, so set one up first
(run this from inside `05-hermes-agent-solar-open2/`):

```bash
hermes_home="$(mktemp -d)"
cp config.yaml "$hermes_home/config.yaml"
touch "$hermes_home/.env"
chmod 755 "$hermes_home"
chmod 644 "$hermes_home/config.yaml" "$hermes_home/.env"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e UPSTAGE_API_KEY \
  -v "$hermes_home:/opt/data" \
  --entrypoint hermes \
  nousresearch/hermes-agent@sha256:bb4d1e414918773b9c40e9a50582d582933beb85029b7050164d125f14e3f417 \
  chat --provider upstage --model solar-open2 \
  --query "Reply with exactly: hermes-ready" --max-turns 2 --quiet --ignore-rules

rm -rf "$hermes_home"
```
