# cloudheim

Valheim dedicated server, deployed to EC2 via GitHub Actions. Container image:
[mbround18/valheim-docker](https://github.com/mbround18/valheim-docker) (Odin).

## Valheim 1.0 revive (September 2026)

- World: `rip_hermeto` (fresh 1.0 world; the old `panerabreade` world lives in
  git history)
- Vanilla at launch. Re-add mods via `TYPE=BepInEx` + `MODS=` in `env.list`
  once their Thunderstore packages have 1.0-compatible builds
  (last checked 2026-09-10: Valheim_Essential stale since 2024-05, MultiUserChest
  since 2025-02).
- `USE_PUBLIC_BETA` removed. In the current image schema it means "track the
  `public-test` branch", which is not what we want.
- **1.0 gotcha:** `permittedlist.txt` / `adminlist.txt` / `bannedlist.txt` IDs
  need a `V_` prefix in 1.0 (e.g. `V_76561198...`). Unprefixed entries no longer
  match, and with `PUBLIC=0` every player gets refused as "banned". See
  [upstream 1.0 upgrade doc](https://github.com/mbround18/valheim-docker/blob/main/docs/tutorials/upgrading_to_valheim_1_0.md).
- Container runs as uid 111 (`steam`) rather than the docs' suggested
  `1000:1000` — see the note in `docker-compose.yml` (upstream
  [issue #1507](https://github.com/mbround18/valheim-docker/issues/1507), open
  as of 2026-09-10).

## How the pieces fit

- `deploy.yml` launches a t3a.medium from launch template
  `lt-00b98ae78e8a14de0`; the template user-data runs `startup.sh`.
- `startup.sh` installs Docker, prepares `/valheim/{saves,server,backups}`
  (uid 111 : gid 1000), seeds `/valheim/saves` from the committed
  `rip_hermeto/` folder, starts the container, and runs `autosave.sh` every
  15 minutes.
- Odin (inside the container) handles auto-update (01:00, skipped while
  players are online) and auto-backup every 15 min to `/valheim/backups`,
  keeping 3 days.
- `autosave.sh` unpacks the newest backup tarball, copies the
  `rip_hermeto.db`/`.fwl` pair into the repo, and pushes `AUTO: Autosave` to
  GitHub (no-op if nothing changed).
- `shutdown.yml` SSHes in, runs `shutdown.sh` (stop container, copy saves,
  push `AUTO: Shutdown save`), then terminates the instance.
- During the terminate itself, `startup.sh` installs
  `cloudheim-shutdown.service`: an ExecStop hook systemd runs on any
  graceful shut down (EC2 terminate sends ACPI), which calls `shutdown.sh`
  again — the guard at the top of that script dedupes the two triggers.
  Terminates issued with "Skip OS shutdown" / `--skip-os-shutdown`, force
  terminate, and hardware failure skip systemd entirely; the 3-min
  autosave timer is the only backstop there (AWS does not guarantee guest
  shutdown scripts run).
- Old `gh repo sync` line was a no-op (it syncs a fork from its parent); the
  autosave loop has been switched to plain `git push` — `template_startup.sh`
  now also runs `gh auth setup-git` so pushes authenticate.

## Ops runbook

```sh
# Launch (GitHub Actions)
#   Actions -> Launch Cloudheim -> Run workflow (template_version default 32)

# Manual autosave status check on the host
cd /cloudheim && ./autosave.sh

# Container shell
docker exec -it $(docker ps -qf name=valheim) bash

# Follow logs
docker logs -f $(docker ps -qf name=valheim)

# Restore a world: stop container, then either replace the 1.0 world
# directory /valheim/saves/worlds_local/rip_hermeto/ (contains
# _main.<gen>.fwl2/.db2/.chunks/.ok) or, for pre-1.0 backups, the legacy
# pair rip_hermeto.db + rip_hermeto.fwl (both must travel together).
# Start container.
```

## World save format (1.0)

A world is now a directory under `worlds_local/`, not a file pair:

```
worlds_local/rip_hermeto/
  _main.<gen>.fwl2     metadata (name, seed, owner)
  _main.<gen>.db2      world data
  _main.<gen>.chunks   chunk index
  _main.<gen>.ok       written when a save completes
  <...>.chunk          terrain, one file per chunk
```

`_main.<gen>.ok` is the completion marker: no `.ok` means no save has
finished yet (a brand-new world has none until the first in-game autosave,
~20 minutes in). Both `autosave.sh` and `shutdown.sh` gate on it so an
unsaved world is never committed, and both still handle the legacy
`.db`/`.fwl` pair for pre-1.0 backup tarballs.

## Legacy

`panerabreade/` (2024 world + ValheimPlus config) was removed in the 1.0
revive; recover it from git history with
`git checkout <pre-revive-commit> -- panerabreade` if ever needed.
