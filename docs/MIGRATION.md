# Migration & Rebind Runbook

The public URLs are **node-name-based, not machine-based**. The funnel ACL and
HTTPS certs were provisioned tailnet-wide when Funnel was first approved, so a
new machine that reuses the node name comes back on the **same URLs** — no
GitHub secret changes needed.

```
https://designlab1.tail68295e.ts.net        -> API server   (127.0.0.1:8642)
https://designlab1.tail68295e.ts.net:8443   -> webhooks     (127.0.0.1:8644)
```

## What travels / what must be recreated

| Asset | Where it lives | Travels with a copy? |
|---|---|---|
| `API_SERVER_KEY`, `WEBHOOK_*` | `~/.hermes/.env` (i.e. `%LOCALAPPDATA%\hermes\.env`) | copy the file |
| config (api_server, webhook enabled) | `config.yaml` | copy the file |
| Profiles / Bots / memory / sessions | `%LOCALAPPDATA%\hermes\profiles\`, `state.db`, `sessions/` | copy (or re-pair) |
| GitHub secrets `HERMES_API_URL` / `HERMES_WEBHOOK_URL` / `HERMES_API_KEY` | repo | unchanged if node name is reused |
| Funnel binding | Tailscale daemon state | **re-created (2 commands)** — certs re-provision automatically |

## Rebind on a new machine (Path A — native gateway)

```bash
# 1. Install Tailscale, join the SAME tailnet, set the SAME node name
tailscale up --hostname=designlab1     # remove/retire the old node first in the admin console

# 2. Install Hermes, restore config + .env + profiles from backup, then:
hermes config set platforms.api_server.enabled true
hermes config set platforms.webhook.enabled true
hermes gateway install && hermes gateway start

# 3. Re-register the callback route
hermes webhook subscribe github-bot-pr --events "bot_pr_complete" \
  --secret "$API_SERVER_KEY" --prompt "..." --deliver log    # see config/hermes-webhook-route.yaml

# 4. Re-bind the funnels (approval link only appears the first time ever per tailnet)
tailscale funnel --bg 8642
tailscale funnel --bg --https 8443 http://127.0.0.1:8644
tailscale serve status

# 5. Verify from OUTSIDE the tailnet (phone on LTE, or wait for DNS — up to 10 min for fresh names)
curl https://designlab1.tail68295e.ts.net/health
curl https://designlab1.tail68295e.ts.net:8443/health

# 6. Only if the hostname changed: update the two URL secrets
gh secret set HERMES_API_URL     --repo Rojman1984/hermes-github-bots --body "https://<machine>.<tailnet>.ts.net"
gh secret set HERMES_WEBHOOK_URL --repo Rojman1984/hermes-github-bots --body "https://<machine>.<tailnet>.ts.net:8443"
```

## Path B — containerized gateway + Tailscale sidecar (full portability)

If you later move the gateway into Docker (e.g. a homelab Linux box), the
portable form is a compose stack where **Tailscale is a sidecar with its own
node identity** — the URL then follows the *container stack*, not any host:

```yaml
# sketch — verify flags against current tailscale docker docs
services:
  tailscale:
    image: tailscale/tailscale:latest
    environment:
      TS_AUTHKEY: ${TS_AUTHKEY}          # reusable auth key (pre-approved for funnel)
      TS_HOSTNAME: designlab1            # keep the name -> keep the URLs
      TS_SERVE_CONFIG: /config/serve.json
    volumes: ["tailscale-state:/var/lib/tailscale", "./serve.json:/config/serve.json"]
    # needs /dev/net/tun (WSL2 backend provides it)
  hermes-gateway:
    image: <hermes image>                # gateway + state volume
    network_mode: "service:tailscale"    # funnel proxies into the shared net
volumes: { tailscale-state: {} }
```

`serve.json` maps `443 -> hermes:8642` and `8443 -> hermes:8644`; the GitHub
secrets never change across migrations because the funnel name lives in the
sidecar config, not the host. Before relying on this path, verify against
https://tailscale.com/kb/1136/tailscale — container Funnel behavior has evolved
across releases.

## Backup checklist (run before any migration)

- `%LOCALAPPDATA%\hermes\` — `config.yaml`, `.env`, `profiles\`, `state.db`, `sessions\`, `auth.json`
- Repo secrets are recoverable from the local `.env` (`API_SERVER_KEY`)
- `tailscale serve status` output (paste into the new box as the target state)