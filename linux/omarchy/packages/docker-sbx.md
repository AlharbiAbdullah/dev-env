# Docker Sandboxes

Requested: 2026-10-26. Source machine: Omarchy desktop hub, x86_64.
Package: `docker-sbx` from the AUR. The package is declared in `aur.txt`.

Status: installed on the hub, version 0.48.0-1. Package integrity, CLI version, daemon health, KVM and Docker authentication pass. Actual parent-child command-only controller tests pass. Native model-worker acceptance remains separate.

The verified installation package is retained at `~/.cache/docker-sbx-0.48.0-1-x86_64.pkg.tar.zst`.

The fresh local network policy is initialized as `allow-all`, preserving outbound capability. Existing policies were not reset. The sandbox daemon runs detached. Proof VMs used one CPU and 1 GiB each and were removed by exact name after collection. General maze capacity defaults are configurable at two CPUs and 2 GiB.

For a fresh machine or later AUR update, use `yay -S docker-sbx`.

The reviewed AUR recipe is version 0.48.0-1. It repackages Docker's official release archive, with a pinned SHA256 matching the upstream asset digest. Upstream currently lists 0.50.0. The installed package uses the maintainer's version without local changes.

The hub has accessible `/dev/kvm`, and actual local shell VM execution is verified. Do not restart Docker Engine or remove existing containers, images or volumes during setup. Never run Docker prune.

## Parity queue

- ARM laptop: install the AUR package, sign in and initialize the fresh local network policy as `allow-all`. Never replace an existing policy silently. The recipe supports aarch64; verify native KVM and runtime behavior on the target.

## Sources

- [AUR package](https://aur.archlinux.org/packages/docker-sbx)
- [Docker installation instructions](https://docs.docker.com/ai/sandboxes/install/)
- [Upstream release](https://github.com/docker/sbx-releases/releases/tag/v0.48.0)
