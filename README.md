# Hermes GitHub Bots — GitHub Actions as a compute plane

Port of [thepopebot](https://github.com/stephengpope/thepopebot)'s GitHub
plumbing to [Hermes Agent](https://github.com/NousResearch/hermes-agent) Bots,
plus three patterns for actually using GitHub's free compute for agent work.

> **Correction to the premise:** thepopebot's agent containers do **not** run
> on GitHub-hosted runners. Its docs (`docs/ARCHITECTURE.md`) are explicit:
> agents run as **local Docker containers** on your host, while GitHub Actions
> (free on public repos / quota on private) handles auto-merge, notification,
> and rebuild plumbing. The workflows below preserve that division of labor
> and add true remote execution via self-hosted runners.

## Free compute facts

| Repo type | Standard hosted runners | Notes |
|---|---|---|
| Public | **Free, unlimited** | `ubuntu-latest` = 4-core / 16 GB / 14 GB SSD |
| Private | 2,000 min/mo (Free) · 3,000 (Pro) · 50,000 (Ent. Cloud) | overage $0.006/min (Linux 2-core) |
| Self-hosted | Free, unlimited | any box you register; needed for >6h jobs |

## What's in here

```
workflows/
  hermes-bot-dispatch.yml   # repository_dispatch/workflow_dispatch → POST to gateway API server (Pattern A)
  bot-pr-loop.yml           # PR opened from bot/* → auto-merge (guarded) → POST completion to Hermes (Pattern B)
  hermes-longrun.yml        # workflow_dispatch → self-hosted runner runs the bot job (Pattern C)
config/
  hermes-webhook-route.yaml # inbound routes for the Hermes gateway (merge into config.yaml)
```

Also installed as a Hermes skill: `github:github-bot-runners` (shows up in
`hermes` sessions via the skills system).

## Architecture

```
                       ┌──────────────────────────────────────────┐
                       │              GitHub repo                  │
                       │  .github/workflows/ (this scaffold)       │
                       └───────┬───────────────────────┬──────────┘
        repository_dispatch /   │                       │  PR opened from bot/*
        workflow_dispatch       ▼                       ▼
                  ┌───────────────────┐        ┌─────────────────────┐
                  │ hermes-bot-       │        │ bot-pr-loop.yml     │
                  │ dispatch.yml      │        │ auto-merge + notify │
                  │ (~1-2 Actions min)│        │ (guarded merge)     │
                  └─────────┬─────────┘        └──────────┬──────────┘
                            │ POST /v1/chat/completions    │ POST /webhooks/github-bot-pr
                            │ model: hermes-<bot>          │ X-Hub-Signature-256 HMAC
                            ▼                              ▼
                  ┌──────────────────────────────────────────────────┐
                  │         Hermes gateway (your machine / VPS)       │
                  │  API server (:8377)   Webhook adapter (:8644)     │
                  │  profiles = Bots → hermes -p <bot> chat           │
                  │  cron = Routines → [bot:<name>] jobs              │
                  └──────────────────────────────────────────────────┘
```

- **Pattern A — dispatch (default):** GitHub-hosted runner costs ~1–2 min to
  kick the bot; the bot does the real work on your hardware. Outbound-only, no
  inbound firewall config needed.
- **Pattern B — PR loop:** the bot works in `bot/<bot>/<task>` branches, opens
  PRs; a hosted runner merges them (respecting `AUTO_MERGE` and
  `ALLOWED_PATHS` vars) and reports back to the bot's webhook route. Results
  land in the bot's chat history like a cron run.
- **Pattern C — long jobs:** register any always-on box as a self-hosted
  runner (labels `self-hosted, hermes-longrun`). GitHub queues and monitors;
  the box executes with no 6h cap.

## Setup

1. **Expose the gateway**
   - API server (Pattern A/C): enable `platforms.api_server.enabled: true` and
     set `API_SERVER_KEY` in `~/.hermes/.env`.
   - Webhooks (Pattern B): run `hermes gateway setup`, or set
     `WEBHOOK_ENABLED=true`, `WEBHOOK_PORT=8644`, `WEBHOOK_SECRET=...` — then
     merge `config/hermes-webhook-route.yaml` into `config.yaml`.
   - GitHub must be able to reach the webhook URL: use ngrok/cloudflared for a
     home machine, or run the gateway on a VPS.
2. **Repo secrets** (repo → Settings → Secrets and variables → Actions):
   - `HERMES_API_URL` — gateway API server base URL (`http://host:8377`)
   - `HERMES_API_KEY` — the `API_SERVER_KEY` value (also used as webhook HMAC secret)
3. **Optional repo variable** `RUNS_ON` — override the runner label
   (defaults to `ubuntu-latest`; set `self-hosted` to route to your box).
4. **Verify**

   ```bash
   curl http://localhost:8644/health        # webhook adapter up?
   hermes webhook list                      # routes registered?
   hermes webhook test github-bot-pr --payload '{"pr_number":"1","pr_title":"t","status":"completed","branch":"bot/x/y","pr_url":"http://x","run_url":"http://x","merged":"true"}'
   ```

5. **Dispatch a test run** (Pattern A):

   ```bash
   gh workflow run hermes-bot-dispatch.yml -f bot=default -f task="Summarize the top post on r/LocalLLaMA"
   gh run watch
   ```

## Security notes

- Never commit `HERMES_API_KEY`; it lives in GitHub Secrets and `~/.hermes/.env` only.
- Public repos are world-readable — fine for the workflows, not for anything secret.
- Webhook routes validate HMAC (fail-closed). The workflow signs callbacks with
  `X-Hub-Signature-256`; raw clients can use `X-Webhook-Signature-V2` +
  `X-Webhook-Timestamp` (±300 s).
- PR/issue content is untrusted input: keep routes' prompts narrow
  (`{pr_title}` over `{__raw__}`), and pin `ALLOWED_PATHS` rather than `/`.
- Auto-merge defaults to permissive in `bot-pr-loop.yml` (matches thepopebot's
  default of allowing everything when unset) — set `ALLOWED_PATHS` (e.g.
  `logs/,docs/`) to restrict what a bot PR may touch before you rely on it.

## Adaptation notes (Hermes ↔ thepopebot mapping)

| thepopebot | Hermes equivalent |
|---|---|
| agent-job Docker container (local) | Bot profile (`hermes -p <bot> chat`) |
| `agent-job/<id>` branch + `agent-job.config.json` | `bot/<bot>/<task>` branch + PR body |
| `auto-merge.yml` | `bot-pr-loop.yml` (same guardrail logic) |
| `notify-pr-complete.yml` → `/api/github/webhook` | webhook route `github-bot-pr` → profile's agent |
| CRONS.json agent jobs | Routines = cron jobs named `[bot:<name>] …` |
| `RUNS_ON` var | same convention, honored by all three workflows |