# XailonHub installer for Windows 11 (x64 and ARM64: Snapdragon X, Core Ultra, Ryzen AI).
#
#   irm https://raw.githubusercontent.com/infinialabs-ai/xailon-hub-releases/main/scripts/install.ps1 | iex
#
# With options:
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/infinialabs-ai/xailon-hub-releases/main/scripts/install.ps1))) -Hub
#   ... -Join studio-hub.local -Pin 123456
#   ... -Code xh1.…
param(
  [switch]$Hub,
  [switch]$Solo,
  [string]$Join = "",
  [string]$Pin = "",
  [string]$Code = "",
  [string]$Name = "",
  [switch]$Lan,
  [switch]$NoStartup,
  [string]$Version = $(if ($env:XAILON_HUB_VERSION) { $env:XAILON_HUB_VERSION } else { "latest" })
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
function Say($m) { Write-Host "==> $m" -ForegroundColor Cyan }

$repo = "infinialabs-ai/xailon-hub-releases"
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") { "arm64" } else { "amd64" }
$asset = "xailon-hub_windows_$arch.zip"
$base = if ($Version -eq "latest") { "https://github.com/$repo/releases/latest/download" } else { "https://github.com/$repo/releases/download/$Version" }
$url = "$base/$asset"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.ServicePointManager]::SecurityProtocol
$dir = Join-Path $env:LOCALAPPDATA "XailonHub\bin"
$exe = Join-Path $dir "xailon-hub.exe"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

Say "Downloading XailonHub for windows/$arch"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("xailon-hub-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Invoke-WebRequest -Uri $url -OutFile (Join-Path $tmp $asset) -UseBasicParsing
  # Refuse a corrupted or tampered archive: it must match the published SHA-256.
  Invoke-WebRequest -Uri "$base/checksums.txt" -OutFile (Join-Path $tmp "checksums.txt") -UseBasicParsing
  $line = Get-Content (Join-Path $tmp "checksums.txt") | Where-Object { $_ -match " $([regex]::Escape($asset))$" } | Select-Object -First 1
  if (-not $line) { throw "checksums.txt has no entry for $asset" }
  $want = ($line -split "\s+")[0].ToLower()
  $got = (Get-FileHash -Algorithm SHA256 (Join-Path $tmp $asset)).Hash.ToLower()
  if ($want -ne $got) { throw "Checksum mismatch for $asset (expected $want, got $got); not installing" }
  Say "Verified SHA-256 $got"
  Get-ScheduledTask -TaskName XailonHub -ErrorAction SilentlyContinue | Stop-ScheduledTask -ErrorAction SilentlyContinue
  Get-Process xailon-hub -ErrorAction SilentlyContinue | Stop-Process -Force
  Expand-Archive -Path (Join-Path $tmp $asset) -DestinationPath $tmp -Force
  Copy-Item (Join-Path $tmp "xailon-hub.exe") $exe -Force
} catch {
  throw "Could not download $url ($($_.Exception.Message)). Check the release exists or build from source with 'go build ./cmd/xailon-hub'."
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
Say "Installed $exe ($(& $exe version))"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not ($userPath -split ";" | Where-Object { $_ -eq $dir })) {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$dir", "User")
  Say "Added $dir to your PATH (open a new terminal to use xailon-hub)"
}

if (-not $NoStartup) {
  # A logon task runs as you, so the hub sees your NPU/GPU drivers and your
  # engines (Ollama, LM Studio, Nexa, Lemonade, OpenVINO). conhost --headless
  # keeps the console window hidden.
  $action = New-ScheduledTaskAction -Execute "conhost.exe" -Argument "--headless `"$exe`" serve"
  $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1)
  Register-ScheduledTask -TaskName "XailonHub" -Action $action -Trigger $trigger -Settings $settings `
    -Description "XailonHub local AI router and agent hub" -Force | Out-Null
  Start-ScheduledTask -TaskName "XailonHub"
  Say "XailonHub starts automatically when you sign in"

  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($isAdmin) {
    foreach ($r in @(@{n="XailonHub peer API"; p="TCP"; port=4748}, @{n="XailonHub discovery"; p="UDP"; port=4749})) {
      if (-not (Get-NetFirewallRule -DisplayName $r.n -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $r.n -Direction Inbound -Protocol $r.p -LocalPort $r.port -Action Allow -Profile Private | Out-Null
      }
    }
  } else {
    Say "If Windows asks, allow XailonHub on Private networks so other devices can reach it"
  }

  $ok = $false
  for ($i = 0; $i -lt 60; $i++) {
    try { Invoke-WebRequest -Uri "http://127.0.0.1:4747/healthz" -UseBasicParsing -TimeoutSec 2 | Out-Null; $ok = $true; break } catch { Start-Sleep -Milliseconds 500 }
  }
  if (-not $ok) { throw "The hub did not start. Run '$exe serve' in a terminal to see why." }
}

$mode = if ($Hub) { "hub" } elseif ($Solo) { "solo" } elseif ($Join -or $Code) { "device" } else { "" }
if ($mode) {
  $a = @("setup", $mode)
  if ($Name) { $a += @("--name", $Name) }
  if ($Join) { $a += @("--join", $Join) }
  if ($Pin) { $a += @("--pin", $Pin) }
  if ($Code) { $a += @("--code", $Code) }
  if ($Hub -and $Lan) { $a += "--lan" }
  & $exe @a
  if ($Hub) { & $exe pair }
} elseif (-not $NoStartup) {
  Start-Process "http://localhost:4747"
}
Say "Dashboard: http://localhost:4747"
