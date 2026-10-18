# XailonHub 0.3.3 — desktop public preview

A native workspace for your Mac, Windows and Linux computers, with an interactive
device map, local AI routing, guided setup and illustrated offline help.

Portal: https://xailonhub.infinialabs.ai
Installation: https://xailonhub.infinialabs.ai/help/install/
User guide: https://xailonhub.infinialabs.ai/help/

## Choose your package

- macOS: Apple Silicon ARM64 or Intel x64 DMG, macOS 12+.
- Windows: ARM64 or Intel/AMD x64 setup.exe, with an offline WebView2 runtime.
- Linux: ARM64 or x64 DEB/RPM. DEB builds target Ubuntu 24.04+ and compatible systems.
- Servers: six CLI archives for macOS, Windows and Linux on ARM64 and x64.

The desktop app includes the Hub, interface and help. AI engines, agents and
model weights are installed separately. The CLI edition uses a browser dashboard.

## Signing and security

This is a public preview. macOS installers are ad-hoc signed, not Apple-notarized;
Windows installers are not publisher-signed. Your OS may show a warning. Verify
`checksums.txt` before installing. Checksums are integrity checks, not publisher
signatures. Do not disable operating-system protections globally.

Desktop administration uses a private, authenticated loopback session. Port 4747
serves inference only in desktop mode. Cloud and relay are off in new setups.
Settings inside the app is the admin console. Closing the app stops its Hub.

Linux GLib 0.18.5 includes the upstream RUSTSEC-2024-0429 iterator fix. Its optimized
unit suite passes with a test-only sentinel-access correction. The patched source
and notes are included. Linux transitive dependencies `proc-macro-error`,
`zbus_names`, `zvariant` and `zvariant_derive` retain unmaintained-package notices;
these are reviewed maintenance risks, not claims of a warning-free dependency tree.
Keep the system WebKitGTK runtime updated.

See `VALIDATION.md`, `THIRD_PARTY_NOTICES.txt`, the Go/Rust SBOMs, and bundled
third-party source archives for verification details and notices.

## Existing users

Stop a CLI Hub before opening the desktop app on the same computer. Back up the
complete state directory and configuration before migration. Do not run two Hubs
with the same node identity. Local network permission may be required to discover
and contact paired devices.

Core application build source: `720809b` in the private source repository.
Application source is not published by this release repository.
