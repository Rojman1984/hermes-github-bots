# Fleet Operations Guide

How the Hermes bot fleet runs on GitHub Actions compute, as of the
tasker-p1 cutover. This is the day-to-day manual: dispatching, routing,
the PR loop, and recovery.

## Architecture (current, verified)

```
                    ┌──────────────────────────── GitHub ────────────────────────────┐
                    │  repo: Rojman1984/hermes-github-bots (public, free Actions)     │
                    │  .github/workflows/                                             │
                    │    hermes-bot-dispatch.yml   (machine input → routes fleet)     │
                    │    joint-task.yml            (cross-machine pipeline)           │
                    │    bot-pr-loop.yml           (auto-merge + callback on bot/* PR)│
                    │    hermes-longrun.yml        (self-hosted runner, long jobs)    │
                    └───────────────┬────────────────────────────────────────────────┘
                                    │  POST /v1/chat/completions        POST /webhooks/github-bot-pr
                                    ▼
        https://tasker-p1.tail68295e.ts.net        https://...:8443   (Tailscale Funnel — the ONLY public door)
                                    │
                                    ▼
┌── TASKER-P1 (always-on Linux, systemd) ──────────────┐   ┌── DESIGNLAB1 (desktop, may sleep) ──┐
│  hermes gateway  :8642 API  :8644 webhooks           │      hermes gateway (native, for the
│  local bots — run dispatches directly                │      desktop app)
│  funnels 443→8642, 8443→8644                         │      API bound to tailnet IP only:
│                                                      │      100.124.135.75:8642 (no public URL)
│  hermes peer designlab1 ── tailnet mesh ─────────────┼──►  reachable only over Tailscale
└──────────────────────────────────────────────────────┘   └─────────────────────────────────────┘
```

## Machine roles

| | tasker-p1 | designlab1 |
|---|---|---|
| Role | **Public edge + always-on host** | Client/desktop; bots reachable via tailnet |
| Public URL | `https://tasker-p1.tail68295e.ts.net` (+`:8443` webhooks) | none (by design) |
| Tailnet | `100.108.64.73` | `100.124.135.75` |
| SSH (tailscale) | `ssh tasker0@tasker-p1` (or `tasker0@100.108.64.73`) | — (Windows; managed from desktop app) |
| Gateway service | `systemctl --user` `hermes-gateway.service` | spawned by desktop app / login item |
| Bots | profiles local to tasker-p1 | profiles local to designlab1 |
| Can sleep? | **No** — it is the dispatcher edge | Yes; `machine=designlab1` tasks pause and re-run |

## Dispatching work

```bash
# tasker-p1 bot (default)
gh workflow run hermes-bot-dispatch.yml -f bot=default -f machine=tasker-p1 \
  -f task="Summarize the latest Hermes release notes"

# designlab1 bot (relayed: tasker-p1's gateway forwards via hermes peer)
gh workflow run hermes-bot-dispatch.yml -f bot=default -f machine=designlab1 \
  -f task="Reply with exactly: ACK"

# watch
gh run watch <run-id> --repo Rojman1984/hermes-github-bots
gh run view <run-id> --repo Rojman1984/hermes-github-bots --log | grep '"content"'
```

The API is OpenAI-compatible: `model: "hermes-<bot>"` selects the profile;
`POST $HERMES_API_URL/v1/chat/completions` with `Authorization: Bearer $HERMES_API_KEY`.
Responses are synchronous (the reply body is in the run log).

## The PR loop (how bots publish work)

1. Bot (or workflow) pushes a branch named **`bot/...`** and opens a PR
2. `bot-pr-loop.yml` fires on `pull_request.opened`:
   waits for mergeability → checks `AUTO_MERGE` (repo variable; `false` disables)
   → checks `ALLOWED_PATHS` (comma-separated prefixes; unset = everything allowed)
   → squash-merges and deletes the branch
3. `notify-hermes` POSTs a signed completion payload to the webhook route
   (`X-Hub-Signature-256` HMAC over exact bytes — `--data-binary`, never `-d`)
4. The route (`github-bot-pr`, event `bot_pr_complete`) wakes the agent, which
   summarizes the outcome; delivery currently `log` (change to `telegram` etc. via
   `hermes webhook remove github-bot-pr` + re-subscribe with `--deliver ...`)

## Cross-machine joint tasks

Pattern (see `joint-task.yml` for the working example):
**stage 1 runs on tasker-p1 → deliverable travels in the task payload →
stage 2 runs on designlab1 via the peer-relay prefix → workflow commits both
deliverables to a `bot/joint/...` branch → PR auto-merges → callback.**

Relay mechanics: tasker-p1's gateway turns a task beginning with
`[PEER-RELAY to designlab1]` into `hermes peer dm designlab1` (its peer config:
`~/.hermes/.env` as `HERMES_PEER_DESIGNLAB1_KEY`, URL in `hermes peer list`).
Peer keys live only in each machine's `.env`; never in the repo.

## Secrets & config reference

GitHub repo secrets (Settings → Secrets and variables → Actions):

| Secret | Value | Notes |
|---|---|---|
| `HERMES_API_URL` | `https://tasker-p1.tail68295e.ts.net` | never changes unless the node is renamed |
| `HERMES_WEBHOOK_URL` | `https://tasker-p1.tail68295e.ts.net:8443` | webhook adapter |
| `HERMES_API_KEY` | tasker-p1's `API_SERVER_KEY` | also the webhook HMAC secret |

On tasker-p1 (`~/.hermes/`): `API_SERVER_KEY`, `WEBHOOK_ENABLED/PORT/SECRET` in
`.env`; `platforms.api_server.enabled`, `platforms.webhook.enabled` in `config.yaml`;
funnels via `tailscale funnel --bg 8642` and `--bg --https 8443 http://127.0.0.1:8644`.
On designlab1: same config keys but `platforms.api_server.host: 100.124.135.75`
(tailnet-only bind) and **no funnels**.

## Adding a new machine / bot

1. Install Tailscale, join tailnet; for SSH access add/confirm the `"ssh"` ACL rule
2. Install Hermes; `hermes config set platforms.api_server.enabled true` + webhook
   platform; generate `API_SERVER_KEY` in its `.env`
3. On tasker-p1: `hermes peer add <machine> --url http://<tailnet-ip>:8642 --key <key>`
4. If it should face the internet: `tailscale funnel --bg ...` (approval needed once
   per tailnet, already granted) — else keep it tailnet-only and peer-relay
5. Create its Bots (Bots tab / `hermes profile create`); extend the workflow's
   `machine` input choices if adding a third target

## Troubleshooting (live-learned)

| Symptom | Cause / fix |
|---|---|
| Runner fails, curl exit 6 | funnel hostname's public DNS not propagated yet (up to 10 min for fresh names) |
| 401 "Invalid signature" in gateway log | signed bytes ≠ sent bytes — must use `--data-binary @payload.json` |
| notify step green but no callback seen | check the **gateway log**, not the GH checkmark: `ssh tasker-p1 'grep bot_pr_complete ~/.hermes/logs/gateway.log \| tail'` |
| `hermes: command not found` over SSH | use `~/.local/bin/hermes`; export `XDG_RUNTIME_DIR=/run/user/$(id -u)` for gateway-aware commands |
| Peer dm "timed out" | peer's API must bind a tailnet-routable address (not 127.0.0.1) |
| Re-run of a failed PR-loop run | re-runs execute the OLD workflow ref — fix on main, open a fresh PR |
| Push rejected after bot PR merge | remote main moved (squash) — `git pull --rebase` then push |

## Cost & safety posture

- Public repo: Actions free/unlimited; nothing sensitive in repo contents; all
  credentials in GitHub Secrets / machine `.env` files
- One public door (tasker-p1 funnel) behind bearer-auth + HMAC; designlab1
  reachable only inside the tailnet
- `ALLOWED_PATHS` is the autonomy dial: set it (e.g. `docs/,logs/`) to restrict
  what bot PRs may touch; `AUTO_MERGE=false` forces human review
- Bots never commit secrets; the repo's key material lives only in secrets