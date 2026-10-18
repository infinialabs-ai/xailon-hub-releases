# XailonHub — public releases

Your computers. Your AI. Better together.

**[Download XailonHub](https://xailonhub.infinialabs.ai/#download)** ·
**[Installation guide](https://xailonhub.infinialabs.ai/help/install/)** ·
**[Illustrated user guide](https://xailonhub.infinialabs.ai/help/)**

This repository distributes XailonHub installers, command-line packages,
checksums and public documentation. The application source is maintained
separately. The portal follows the Infinia Labs product design system.

## Downloads

Choose an asset from [Releases](https://github.com/infinialabs-ai/xailon-hub-releases/releases).

| Computer | Desktop package | Server / command-line package |
| --- | --- | --- |
| Apple Silicon Mac | macOS ARM64 DMG | darwin_arm64.tar.gz |
| Intel Mac | macOS x64 DMG | darwin_amd64.tar.gz |
| Windows on Snapdragon / ARM | Windows ARM64 setup.exe | windows_arm64.zip |
| Windows on Intel / AMD | Windows x64 setup.exe | windows_amd64.zip |
| Linux ARM64 / aarch64 | ARM64 DEB / RPM | linux_arm64.tar.gz |
| Linux Intel / AMD | x64 DEB / RPM | linux_amd64.tar.gz |

The desktop app includes the Hub backend, interface and offline illustrated help.
AI engines and models are separate installations. Windows installers include the
offline WebView2 runtime. Linux packages use WebKitGTK system libraries.

## Public-preview signing status

macOS builds are ad-hoc signed, not Apple-notarized. Windows builds are not
publisher-signed. The operating system may show a warning. Verify the SHA-256
checksum against `checksums.txt` in the same release. Checksums do not replace a
trusted publisher signature. See the installation guide before proceeding.

## CLI installation

These install the **CLI edition**, which uses a browser dashboard:

```sh
curl -fsSL https://xailonhub.infinialabs.ai/install.sh | sh
```

```powershell
irm https://xailonhub.infinialabs.ai/install.ps1 | iex
```

Inspect scripts before running them. `--no-service` (shell) and `-NoStartup`
(PowerShell) install without registering a background service.

## Help and security

Open **Settings inside the desktop app** for administration. The normal port
4747 serves inference only in desktop mode. Closing the app stops its Hub.

Report ordinary bugs through Issues without including private prompts or keys.
Report security vulnerabilities privately to hello@infinialabs.ai with subject
“XailonHub security”. Read [security and privacy](https://xailonhub.infinialabs.ai/security/).

## Maintain this portal

- `release.json` describes the verified desktop artifacts.
- `site/assets/help/guide.json` and screenshots are copied from the app's guide.
- `python3 scripts/build-site.py` regenerates pages and the sitemap.
- `wrangler deploy` deploys the static site with the configured custom domain.
- Provide Cloudflare credentials through the environment; never commit `.env`.

Powered by Infinia. © 2026 Infinia Technologies.
