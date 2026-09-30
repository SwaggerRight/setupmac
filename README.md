# setupmac

An Ansible-based macOS setup project migrated from an Intel Mac to an Apple
Silicon M5 Pro.

## Migration status

The reviewed baseline is now implemented with native Homebrew packages,
current application casks, Company Portal-aware VS Code extension management,
shell configuration, and current Microsoft administration PowerShell modules. The original
`roles/setup` files remain only as migration history and are not called.

## Inventory the current Intel Mac

Clone this branch on the Mac you want to reproduce, then run:

```bash
./scripts/inventory-mac.sh
```

Output is written to a timestamped directory under `inventory-output/`, which
is excluded from Git. In addition to package and preference data, the inventory
creates `intel-only-applications.tsv` to identify apps that may require an
Apple Silicon upgrade or Rosetta. Read the generated `REVIEW-ME.md` before
sharing or committing any inventory data.

You may choose a different output directory:

```bash
./scripts/inventory-mac.sh "$HOME/Desktop/mac-inventory"
```

## Bootstrap the Apple Silicon Mac

After cloning this repository on the target Mac:

```bash
./bootstrap.sh
```

The bootstrap script verifies Xcode Command Line Tools, installs Homebrew when
needed, chooses `/opt/homebrew` on Apple Silicon or `/usr/local` on Intel,
installs Git and Ansible, applies the baseline Brewfile interactively, installs
required collections, and runs the localhost playbook. The interactive
Homebrew step allows package installers to request macOS administrator approval
without putting a password in the repository.

Rosetta is not installed automatically. Prefer native Apple Silicon software.
Additional profiles can be enabled explicitly through the bootstrap script:

```bash
./bootstrap.sh --with-optional --with-virtualization --with-app-store
```

Rosetta-dependent applications are skipped unless `--with-rosetta` is supplied.
That option refuses to run until Rosetta has already been installed
intentionally.

## Safe reruns

Running `./bootstrap.sh` again is expected and safe. Homebrew Bundle installs
missing declared items without uninstalling unrelated software, Ansible updates
only settings that differ, shell blocks are not duplicated, and existing
PowerShell modules are retained. Use the same `--with-*` flags on a later run
when you want those optional profiles checked and restored as well.

The bootstrap may refresh Git, Ansible, and the Ansible collection itself, but
the Brewfiles use `--no-upgrade`, so a rerun does not perform a wholesale
application upgrade.

## Manual steps

See [`docs/manual-steps.md`](docs/manual-steps.md) for settings that require
interactive account sign-in or macOS Privacy & Security approval.

See [`docs/migration-review.md`](docs/migration-review.md) for the Intel-to-M5
software decisions, excluded legacy applications, and vendor-managed installs.
