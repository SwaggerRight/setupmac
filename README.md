# setupmac

An Ansible-based macOS setup project. This branch begins the migration from the
original Intel-era configuration to a current Apple Silicon Mac.

## Migration status

The original `roles/setup` role is preserved, but it is disabled by default
because its package and cask inventory requires review. The first step is to
inventory the existing Intel Mac and use that output to build ARM-native roles
and a reviewed `Brewfile` deliberately.

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
installs Git and Ansible, installs required collections, and runs the localhost
playbook.

Rosetta is not installed automatically. Prefer native Apple Silicon software;
install Rosetta only if the reviewed inventory identifies a required Intel-only
application with no native alternative.

The legacy role is disabled until its contents have been reviewed and migrated.
For inspection only, it can be explicitly selected with:

```bash
ansible-playbook playbook.yml --tags legacy -e run_legacy_setup=true
```

Do not enable it on a new Mac yet. Several packages and casks are obsolete.

## Manual steps

See [`docs/manual-steps.md`](docs/manual-steps.md) for settings that require
interactive account sign-in or macOS Privacy & Security approval.
