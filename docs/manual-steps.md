# Manual setup checklist

Some macOS security and account settings require explicit user approval and
should not be forced by a personal Ansible playbook.

- If this Mac will be company-managed, install Company Portal from the
  organization's enrollment link, complete Intune enrollment, and install
  required company applications before running the personal software profile.
- Sign in to the Apple Account and select the desired iCloud services.
- Sign in to the password manager before restoring credentials.
- Configure Touch ID and Apple Pay.
- Turn on FileVault and record the recovery key safely.
- Approve required Privacy & Security permissions, including Accessibility,
  Screen Recording, Camera, Microphone, and Full Disk Access.
- Approve required system extensions and network extensions.
- Review `intel-only-applications.tsv` and install Rosetta only when a required
  application has no native Apple Silicon version.
- Install corporate and vendor-managed software listed in
  `docs/migration-review.md` through the appropriate MDM or vendor installer.
- Sign in to the Mac App Store before enabling the `Brewfile.mas` profile.
- Sign in to Microsoft 365, browsers, development tools, and other applications.
