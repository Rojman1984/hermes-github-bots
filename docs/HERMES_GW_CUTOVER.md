# hermes-gw Cutover Runbook

Move the production gateway from the native systemd service on tasker-p1 to
the containerized `hermes-gw` stack (`deploy/hermes-gw/docker-compose.yml`).

End state: the funnel URLs belong to a dedicated Tailscale node **inside the
stack**. Any Docker host + these files + the data volume = the whole public
edge of the fleet.

## Prerequisites (once)

- [ ] Docker + compose plugin on target host (tasker-p1: verified 29.6.2 / v5.3.1)
- [ ] **YOU:** mint a pre-auth key at <https://login.tailscale.com/admin/settings/keys>
      (Reusable OFF, Ephemeral OFF, Tags: none for v1, Expiry: 90 days)
- [ ] **YOU:** create the OAuth client for the provisioning identity (v2, later)

## Phase 0 — stand up beside native (zero downtime)

```bash
ssh tasker0@tasker-p1
sudo mkdir -p /opt/hermes-gw && sudo chown tasker0 /opt/hermes-gw
git clone --depth 1 https://github.com/Rojman1984/hermes-github-bots.git /opt/hermes-gw/repo
cd /opt/hermes-gw/repo/deploy/hermes-gw

# .env (never committed): TS_AUTHKEY=<pre-auth key>, HERMES_UID/GID=$(id -u):$(id -g)
umask 077; printf 'TS_AUTHKEY=%s\nHERMES_UID=%s\nHERMES_GID=%s\n' \
  "$TS_AUTHKEY_VALUE" "$(id -u)" "$(id -g)" > .env

docker compose up -d
docker compose logs ts  | grep -i funnel     # expect: https://hermes-gw.<tailnet>.ts.net
docker compose logs gw  | tail -5            # expect s6 gateway startup
curl -s https://hermes-gw.<tailnet>.ts.net/health
```

First boot seeds a FRESH data dir. To carry over state (profiles, memory,
webhook routes), stop here and do the data migration in Phase 2 instead.

## Phase 1 — data migration (stop-copy-start; single-writer rule)

```bash
# stop the NATIVE gateway first — never two gateways on one data dir
systemctl --user stop hermes-gateway

tar -C ~/.hermes -cf - . | tar -C /opt/hermes-gw/repo/deploy/hermes-gw/data -xf -
# fix ownership to the container uid if needed:
sudo chown -R 10000:10000 /opt/hermes-gw/repo/deploy/hermes-gw/data

docker compose up -d
curl -s https://hermes-gw.<tailnet>.ts.net/health   # ok
curl -s https://hermes-gw.<tailnet>.ts.net:8443/health
```

## Phase 2 — repoint GitHub (one-time URL rotation)

```bash
GH="/c/Program Files/GitHub CLI/gh.exe"
"$GH" secret set HERMES_API_URL     --repo Rojman1984/hermes-github-bots \
  --body "https://hermes-gw.<tailnet>.ts.net"
"$GH" secret set HERMES_WEBHOOK_URL --repo Rojman1984/hermes-github-bots \
  --body "https://hermes-gw.<tailnet>.ts.net:8443"
```

Then prove both legs:
- dispatch: `gh workflow run hermes-bot-dispatch.yml -f bot=default -f task="Reply GW_OK"`
- webhook: signed `bot_pr_complete` POST → expect HTTP 202 in gateway log

## Phase 3 — retire native, soak

```bash
systemctl --user disable hermes-gateway   # keep files for rollback, stop autostart
# designlab1's funnel was already retired; tasker-p1 native funnels:
#   tailscale funnel --https=443 off ; tailscale funnel --https=8443 off
```

Rollback (within the soak window): `systemctl --user enable --now hermes-gateway`,
revert the two secrets. Keep the native data dir untouched for 7 days.

## First-boot config inside the container

```bash
docker exec -it hermes-gw hermes setup --portal   # auth token persists in /opt/data
```

Profiles are created normally (`hermes profile create scout` …) — the official
image supervises each profile as its own s6 service with per-profile logs.
Never run a second gateway container against the same ./data.