#!/bin/sh
# XailonHub installer for macOS and Linux (x86-64 and ARM64, incl. GB10).
#
#   curl -fsSL https://raw.githubusercontent.com/infinialabs-ai/xailon-hub-releases/main/scripts/install.sh | sh
#
# Options (after `sh -s --`):
#   --hub                    make this machine the Hub (edge box / AI companion)
#   --join HOST --pin PIN    join a Hub using the PIN it shows
#   --code xh1.…             join a Hub using an invite code
#   --solo                   use this computer on its own
#   --name NAME              display name for this machine
#   --lan                    (with --hub) let phones/apps on the LAN use the API
#   --no-service             install the binary only
#
# Environment: XAILON_HUB_VERSION (default latest), XAILON_HUB_BIN (default
# ~/.local/bin), XAILON_HUB_DOWNLOAD_BASE (internal mirror of release files)
set -eu

REPO=infinialabs-ai/xailon-hub-releases
VERSION=${XAILON_HUB_VERSION:-latest}
BIN_DIR=${XAILON_HUB_BIN:-$HOME/.local/bin}
MODE="" JOIN="" PIN="" CODE="" NAME="" LAN="" SERVICE=1

while [ $# -gt 0 ]; do
  case "$1" in
    --hub) MODE=hub ;;
    --solo) MODE=solo ;;
    --join) MODE=device; JOIN=$2; shift ;;
    --pin) PIN=$2; shift ;;
    --code) MODE=device; CODE=$2; shift ;;
    --name) NAME=$2; shift ;;
    --lan) LAN=--lan ;;
    --no-service) SERVICE=0 ;;
    -h|--help) echo "usage: install.sh [--hub [--lan] | --join HOST --pin PIN | --code CODE | --solo] [--name NAME] [--no-service]"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

os=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$os" in darwin|linux) ;; *) die "unsupported OS $os (use scripts/install.ps1 on Windows)";; esac
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) die "unsupported CPU $(uname -m)" ;;
esac
# An x86 shell under Rosetta still gets the native arm64 build.
if [ "$os" = darwin ] && [ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" = 1 ]; then arch=arm64; fi

asset="xailon-hub_${os}_${arch}.tar.gz"
if [ "$VERSION" = latest ]; then
  base="https://github.com/$REPO/releases/latest/download"
else
  base="https://github.com/$REPO/releases/download/$VERSION"
fi
# XAILON_HUB_DOWNLOAD_BASE points at an internal mirror (air-gapped sites);
# the archive is still verified against the mirror's checksums.txt.
base=${XAILON_HUB_DOWNLOAD_BASE:-$base}
url="$base/$asset"

sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$BIN_DIR"
say "Downloading XailonHub for $os/$arch"
if curl -fsSL --proto '=https,http' "$url" -o "$tmp/$asset" 2>/dev/null; then
  # Refuse a corrupted or tampered archive: it must match the release's
  # published SHA-256.
  curl -fsSL --proto '=https,http' "$base/checksums.txt" -o "$tmp/checksums.txt" || die "could not download checksums.txt to verify $asset"
  want=$(grep " $asset\$" "$tmp/checksums.txt" | cut -d' ' -f1)
  got=$(sha256 "$tmp/$asset")
  [ -n "$want" ] && [ "$want" = "$got" ] || die "checksum mismatch for $asset (expected ${want:-none}, got $got); not installing"
  say "Verified SHA-256 $got"
  tar -xzf "$tmp/$asset" -C "$tmp"
  install -m 0755 "$tmp/xailon-hub" "$BIN_DIR/xailon-hub"
else
  die "could not download $url; check your network or choose a package at https://xailonhub.infinialabs.ai"
fi
BIN="$BIN_DIR/xailon-hub"
say "Installed $BIN ($("$BIN" version))"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) say "Add $BIN_DIR to your PATH to run xailon-hub from any terminal" ;; esac

if [ "$SERVICE" = 1 ]; then
  if [ "$os" = darwin ]; then
    plist="$HOME/Library/LaunchAgents/ai.infinialabs.xailon-hub.plist"
    logdir="$HOME/Library/Logs"
    mkdir -p "$(dirname "$plist")" "$logdir"
    cat >"$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>ai.infinialabs.xailon-hub</string>
  <key>ProgramArguments</key><array><string>$BIN</string><string>serve</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$logdir/xailon-hub.log</string>
  <key>StandardErrorPath</key><string>$logdir/xailon-hub.log</string>
</dict>
</plist>
PLIST
    launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist"
    say "Started at login via launchd (log: $logdir/xailon-hub.log)"
  elif command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    unit="$HOME/.config/systemd/user/xailon-hub.service"
    mkdir -p "$(dirname "$unit")"
    cat >"$unit" <<UNIT
[Unit]
Description=XailonHub local AI router and agent hub
After=network-online.target

[Service]
ExecStart=$BIN serve
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
UNIT
    systemctl --user daemon-reload
    systemctl --user enable --now xailon-hub.service >/dev/null
    systemctl --user restart xailon-hub.service
    # Keep the hub running without an open login session (headless edge boxes).
    loginctl enable-linger "$(id -un)" 2>/dev/null || say "Tip: run 'sudo loginctl enable-linger $(id -un)' so the hub runs before you log in"
    say "Started as a systemd user service (logs: journalctl --user -u xailon-hub -f)"
  else
    nohup "$BIN" serve >"$HOME/.xailon-hub.log" 2>&1 &
    say "Started in the background (log: ~/.xailon-hub.log); add '$BIN serve' to your startup apps"
  fi

  i=0
  until curl -fsS http://127.0.0.1:4747/healthz >/dev/null 2>&1; do
    i=$((i + 1)); [ $i -gt 60 ] && die "the hub did not start; check its log"
    sleep 0.5
  done
fi

if [ -n "$MODE" ]; then
  set -- "$MODE"
  [ -n "$NAME" ] && set -- "$@" --name "$NAME"
  [ -n "$JOIN" ] && set -- "$@" --join "$JOIN"
  [ -n "$PIN" ] && set -- "$@" --pin "$PIN"
  [ -n "$CODE" ] && set -- "$@" --code "$CODE"
  if [ "$MODE" = hub ] && [ -n "$LAN" ]; then set -- "$@" --lan; fi
  "$BIN" setup "$@"
  if [ "$MODE" = hub ]; then "$BIN" pair; fi
fi

if [ "$SERVICE" = 0 ]; then
  say "Run '$BIN start' to launch the hub and open the dashboard"
  exit 0
fi
say "Dashboard: http://localhost:4747"
if [ -z "$MODE" ]; then
  if [ "$os" = darwin ]; then open http://localhost:4747 2>/dev/null || true
  elif [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then xdg-open http://localhost:4747 >/dev/null 2>&1 || true
  fi
fi
