# Intel-to-M5 Pro migration review

This review was generated from the Intel Mac inventory collected on
September 30, 2026.

## Automated in the baseline

- Top-level command-line, security, cloud, and development tools are installed
  from the native Apple Silicon Homebrew prefix (`/opt/homebrew`).
- Current casks replace the old Intel copies of applications such as Docker,
  Dropbox, KeePassXC, OBS, Signal, Spotify, VS Code, Webex, Zoom, and RingCentral.
- VS Code extensions are curated to remove obsolete or Mac-inapplicable entries.
- Current Microsoft Graph and Exchange Online PowerShell modules replace the
  duplicate versions found on the Intel Mac.

## Optional profiles

- `Brewfile.optional` contains creative, gaming, and specialty applications.
- `Brewfile.virtualization` contains VirtualBox and Vagrant. Use ARM64 guest
  images; existing Intel/x86 VMs cannot run natively on the M5 Pro.
- `Brewfile.rosetta` contains software that still requires Rosetta.
- `Brewfile.mas` contains selected Mac App Store purchases and requires an
  interactive App Store sign-in before it is enabled.

Enable profiles when running the playbook:

```bash
sudo -v
ansible-playbook playbook.yml \
  -e install_optional_apps=true \
  -e install_virtualization_apps=true \
  -e install_app_store_apps=true
```

The normal `./bootstrap.sh` path runs the baseline Brewfile directly in the
interactive terminal before Ansible. This allows macOS to request administrator
approval for application packages without storing a password in the repository.

If Rosetta applications are still required after reviewing native alternatives,
install Rosetta explicitly and then enable that profile:

```bash
sudo softwareupdate --install-rosetta --agree-to-license
sudo -v
ansible-playbook playbook.yml -e install_rosetta_apps=true
```

## Deliberately excluded legacy software

- Android File Transfer
- Garmin WebUpdater and the older Garmin mapping utilities
- H&R Block 2022, 2023, and 2024
- Keyspan Serial Assistant (PowerPC/32-bit)
- Logitech Camera Settings (32-bit)
- Skype for Business
- SwiftDefaultApps preference pane
- TextWrangler
- Vagrant Manager
- Visual Studio for Mac
- WineBottler and the duplicate Wine installations
- YubiKey Manager (replaced by Yubico Authenticator)
- Zenmap (use the supported `nmap` command-line tools)

## Vendor, MDM, or security approval installs

Install these through the owning organization, vendor, or MDM rather than
Homebrew so that profiles, certificates, system extensions, and licenses are
applied correctly:

- Company Portal, Intune components, and Microsoft Remote Help
- F5 VPN and UniFi Endpoint
- Omnissa Horizon Client and VMware Fusion
- PreVeil
- Adobe Creative Cloud and Acrobat components
- ClickShare and Meeting Owl software
- CH34x and CP210x serial drivers
- Poly/Plantronics, Logitech, HP, and printer/scanner utilities
- xTool Studio and licensed LightBurn configuration

## PowerShell cleanup

The Intel inventory contained several side-by-side Microsoft Graph versions and
the legacy `AzureAD`/`AzureADPreview` modules. The new build installs only the
current `Microsoft.Graph`, `Microsoft.Graph.Beta`, and
`ExchangeOnlineManagement` modules. Scripts that still import `AzureAD` should
be converted to Microsoft Graph instead of restoring those modules.
