# Windrose on Pelican

An unofficial adapter for the publisher's native Linux Windrose dedicated server. No game executable is patched. The local build pulls the pinned publisher image directly. This repository does not mirror the game files or distribute a prebuilt image containing them.

## Deployment

The registry workflow builds and tests an adapter-only runtime. Import [the registry egg](egg-windrose-linux-registry.yaml), create a server and start it from Pelican. During installation, the egg fetches and verifies the publisher's original Linux game layer directly from Docker Hub. The GHCR image contains the adapter and runtime dependencies. The game files live in the server volume.

Both the installer and runtime references are pinned to the [verified public GHCR build](https://github.com/TheIlluminate92/windrose-pelican/actions/runs/45923432866).

## Local build and import

Requires Docker with BuildKit on Linux amd64. Run `./build.sh`, then import `egg-windrose-linux.yaml` in Pelican. The egg uses a cache-only image, so build it on each Wings node that will host this egg. The installer creates the initial server config and save directory. Start via Pelican after installation.

Set a join password and use the primary allocation for Direct IP. Set both **World Name** and **World Difficulty** before the first start, or leave both blank for Windrose's defaults. First-world setup requires **Recover From Latest Backup** enabled. Leave the temporary high port range (49152–65535) out of the server's published allocations. Changes to these fields on existing worlds have no effect.

## What the adapter changes

- Makes the game config and save paths use the Wings-managed volume and gives the backup staging path a private writable directory.
- Waits for the real gameplay map log line. The lobby can open its listener earlier.
- When first-world settings are requested, runs the game on an unpublished high port with a temporary password. It waits for a CRC-verified native backup before sending the regular stop signal. It preserves the original archive and RocksDB directory, patches only the archived world descriptor, then verifies the same world and new settings after cold restore.
- Interrupted or unexpected first-run steps leave a held state with the original files. Do not clear `.windrose-first-run` or move its files until you have reconciled the current world and backup offline.

## Verification and known limits

The linked GitHub Actions run verified the publisher installer and first-run settings through two actual engine starts in isolation. A fresh server then installed and started through Pelican using the same public digest. The Panel reported it running, and its world files confirmed the configured name and Hard difficulty after the first-run restore. A player join had yet to be confirmed at that checkpoint.

The publisher build `0.10.0.9.32-22d39a16` can segfault after reaching its shutdown path. The unmodified publisher image reproduced this in an isolated test. Its shell wrapper can mask the crash by returning 0. This adapter preserves the game's exit status. A stop is not a backup, and exit 139 does not establish that recent saves flushed.

Official references: [publisher's server guide](https://playwindrose.com/dedicated-server-guide), [publisher's Docker image](https://hub.docker.com/r/windroseserver/windroseserver), [Pelican egg docs](https://pelican.dev/docs/eggs/creating-a-custom-egg/).

## Attribution

The egg builds on the [Pelican Windrose egg](https://github.com/pelican-eggs/games-steamcmd/pull/271) by nezorflame and contributors. The upstream MIT notice is included. Windrose and its game files remain the publisher's property.

OpenAI Codex assisted with implementation, tests, and documentation under the operator's direction. The game behavior statements above distinguish isolated observations from production acceptance.
