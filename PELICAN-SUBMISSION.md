# Windrose native Linux contribution

The community package uses the public [adapter-only runtime](https://github.com/TheIlluminate92/windrose-pelican/pkgs/container/windrose-pelican-runtime). The importer and runtime fetch the pinned version through normal Pelican operations. During install, the adapter verifies the publisher's original Docker layer and extracts the unchanged Linux server into the Wings-managed volume. The public adapter image does not contain game files.

## Upstream order

1. Review the adapter in [the Pelican Yolks draft PR](https://github.com/pelican-eggs/yolks/pull/386). Include the pinned publisher and build dependency provenance, runtime source and license, bounded installer, and [actual-engine verification](https://github.com/TheIlluminate92/windrose-pelican/actions/runs/45924264396). Keep the startup wrapper in the Yolk so a game-panel user cannot edit it through the server volume. The existing community image is reference material. The [Games SteamCMD contribution policy](https://github.com/pelican-eggs/games-steamcmd/blob/0547150ac32eceac7a1aefb2353aae36b5d2f321/CONTRIBUTING.md) requires an approved stock Yolk.
2. After upstream publishes that Yolk, pin its immutable reference for both the installer and runtime. Import it into Pelican, create an isolated fresh Linux amd64 server, and export the exact tested egg from the Panel. Run install, first-start world settings, recovery, and a real Direct IP join on that exact image.
3. Submit the native Linux egg and its separate README as an alternate in [the existing Windrose directory](https://github.com/pelican-eggs/games-steamcmd/tree/0547150ac32eceac7a1aefb2353aae36b5d2f321/windrose), alongside the existing SteamCMD egg. Coordinate the repository placement with the maintainers since the Linux package is publisher Docker content. Keep the two routes clearly labeled.

## Reviewer test notes

- Platform is Linux amd64. Direct IP uses the primary game allocation, and join passwords are limited to 31 characters.
- For first-run testing, choose a world name and preset, enable recovery from latest backup, and leave the high port range unpublished. Verify gameplay readiness, the same restored world, and the requested preset. Later starts preserve that world.
- The vendor build can exit 139 after regular shutdown. Report it as a publisher crash. A native backup and a successful cold restore were independently observed.
- Joining was confirmed in Pelican on the preceding public image with a shorter password. The package's pinned password-limit build passed isolated actual-engine install and first-run CI. Official Yolk publication and a live test of its exported egg remain pending.
- Player-count integration is optional and outside the egg/Yolk submission.

## Proposed PR description

Add a native Linux Windrose deployment path using the publisher's pinned Linux payload. The approved Yolk supplies the adapter, while Pelican installation downloads the original game files directly from the publisher. Wings owns the persistent configuration and save paths. The egg exposes Direct IP and supported settings, applies optional world settings on first launch, and preserves the existing world on later starts.

The contribution is based on the existing Windrose egg and preserves its upstream attribution and MIT notice. OpenAI Codex assisted with implementation, testing, and documentation. See the public source and verification links above.
