#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$App,

    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Usage: .\init.ps1 <app>

Example:
  .\init.ps1 opencode

This creates a symlink from this repo's <app>/ to `%APPDATA%/<app>
(or ~/AppData/Roaming/<app> if APPDATA is unavailable).

Exceptions:
  - for 'copilot', the link target is ~/.copilot
  - for 'ssh', sync only ssh/config -> ~/.ssh/config
  - for 'opencode', the link target is ~/.config/opencode
  - for 'nvim', initializes the git submodule first (if configured), then links to %LOCALAPPDATA%/nvim
  - for 'pwsh', the link target is ~/Documents/PowerShell
  - for 'wezterm', links config dir to ~/.config/wezterm and ensures ~/.wezterm.lua exists
  - for 'git', symlink git/.gitconfig -> ~/.gitconfig and
    git/.gitignore_global -> ~/.gitignore_global

Notes:
  - 'zsh' and 'rime' are not supported in this PowerShell script.
  - If destination exists and is not the desired link, it is moved to
    <dest>.bak.<timestamp> first.
"@
}

function Resolve-StrictPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-LinkTarget {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.LinkType) {
        return $null
    }

    $target = $item.Target
    if ($target -is [Array]) {
        $target = $target[0]
    }
    if ([string]::IsNullOrWhiteSpace($target)) {
        return $null
    }

    try {
        return (Resolve-Path -LiteralPath $target).Path
    } catch {
        return $target
    }
}

function Get-ConfigHome {
    if (-not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
        return $env:APPDATA
    }

    return (Join-Path $HOME "AppData/Roaming")
}

function Ensure-SubmoduleReady {
    param(
        [Parameter(Mandatory = $true)][string]$RepoDir,
        [Parameter(Mandatory = $true)][string]$SubmodulePath
    )

    $gitmodules = Join-Path $RepoDir ".gitmodules"
    if (-not (Test-Path -LiteralPath $gitmodules -PathType Leaf)) {
        return
    }

    $escapedPath = [regex]::Escape($SubmodulePath)
    $declared = Select-String -LiteralPath $gitmodules -Pattern "^\s*path\s*=\s*$escapedPath\s*$" -Quiet
    if (-not $declared) {
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "error: git is required to initialize submodule '$SubmodulePath', but it was not found in PATH"
    }

    Write-Host "syncing submodule: $SubmodulePath"
    & git -C $RepoDir submodule update --init --recursive -- $SubmodulePath
    if ($LASTEXITCODE -ne 0) {
        throw "error: failed to initialize submodule '$SubmodulePath'"
    }
}

function Link-Path {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestPath
    )

    $srcAbs = Resolve-StrictPath $SourcePath
    $destParent = Split-Path -Parent $DestPath
    if (-not [string]::IsNullOrWhiteSpace($destParent)) {
        New-Item -ItemType Directory -Path $destParent -Force | Out-Null
    }

    $currentTarget = Get-LinkTarget $DestPath
    if ($currentTarget -and $currentTarget -eq $srcAbs) {
        Write-Host "ok: already linked: $DestPath -> $srcAbs"
        return
    }

    if (Test-Path -LiteralPath $DestPath) {
        $ts = Get-Date -Format "yyyyMMddHHmmss"
        $backup = "$DestPath.bak.$ts"
        Move-Item -LiteralPath $DestPath -Destination $backup
        Write-Host "moved aside: $DestPath -> $backup"
    }

    $isDir = Test-Path -LiteralPath $srcAbs -PathType Container

    try {
        New-Item -ItemType SymbolicLink -Path $DestPath -Target $srcAbs | Out-Null
        Write-Host "linked: $DestPath -> $srcAbs"
        return
    } catch {
        if (-not $isDir) {
            throw
        }

        New-Item -ItemType Junction -Path $DestPath -Target $srcAbs | Out-Null
        Write-Host "linked (junction): $DestPath -> $srcAbs"
    }
}

function Write-WeztermLoader {
    param(
        [Parameter(Mandatory = $true)][string]$DestPath
    )

    if (Test-Path -LiteralPath $DestPath) {
        $ts = Get-Date -Format "yyyyMMddHHmmss"
        $backup = "$DestPath.bak.$ts"
        Move-Item -LiteralPath $DestPath -Destination $backup
        Write-Host "moved aside: $DestPath -> $backup"
    }

    $loader = @'
local home = os.getenv("USERPROFILE") or os.getenv("HOME")
local config_dir = home .. "/.config/wezterm"

package.path = table.concat({
  package.path,
  config_dir .. "/?.lua",
  config_dir .. "/?/init.lua",
}, ";")

return dofile(config_dir .. "/wezterm.lua")
'@

    Set-Content -LiteralPath $DestPath -Value $loader -Encoding Ascii
    Write-Host "wrote loader: $DestPath"
}

if ($Help -or $App -eq "-h" -or $App -eq "--help" -or [string]::IsNullOrWhiteSpace($App)) {
    Show-Usage
    if ([string]::IsNullOrWhiteSpace($App) -and -not $Help) {
        exit 1
    }
    exit 0
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($App -eq "zsh" -or $App -eq "rime") {
    throw "error: '$App' is not supported by init.ps1. Use init.sh in a Unix-like shell for this app."
}

if ($App -eq "git") {
    $gitconfigSrc = Join-Path $scriptDir "git/.gitconfig"
    $gitignoreSrc = Join-Path $scriptDir "git/.gitignore_global"

    if (-not (Test-Path -LiteralPath $gitconfigSrc -PathType Leaf) -or -not (Test-Path -LiteralPath $gitignoreSrc -PathType Leaf)) {
        throw "error: git config files not found under: $scriptDir/git"
    }

    Link-Path -SourcePath $gitconfigSrc -DestPath (Join-Path $HOME ".gitconfig")
    Link-Path -SourcePath $gitignoreSrc -DestPath (Join-Path $HOME ".gitignore_global")
    exit 0
}

if ($App -eq "ssh") {
    $sshConfigSrc = Join-Path $scriptDir "ssh/config"
    if (-not (Test-Path -LiteralPath $sshConfigSrc -PathType Leaf)) {
        throw "error: ssh config not found at: $sshConfigSrc"
    }

    $sshDestDir = Join-Path $HOME ".ssh"
    New-Item -ItemType Directory -Path $sshDestDir -Force | Out-Null

    $sshConfigDest = Join-Path $sshDestDir "config"
    Link-Path -SourcePath $sshConfigSrc -DestPath $sshConfigDest
    exit 0
}

if ($App -eq "wezterm") {
    $weztermSrcDir = Join-Path $scriptDir "wezterm"
    if (-not (Test-Path -LiteralPath $weztermSrcDir -PathType Container)) {
        throw "error: app '$App' not found at: $weztermSrcDir"
    }

    $weztermDestDir = Join-Path $HOME ".config/wezterm"
    Link-Path -SourcePath $weztermSrcDir -DestPath $weztermDestDir

    $weztermMain = Join-Path $weztermDestDir "wezterm.lua"
    $weztermHome = Join-Path $HOME ".wezterm.lua"

    try {
        Link-Path -SourcePath $weztermMain -DestPath $weztermHome
    } catch {
        Write-Host "warn: could not symlink ~/.wezterm.lua; writing loader file instead"
        Write-WeztermLoader -DestPath $weztermHome
    }

    exit 0
}

if ($App -eq "pwsh") {
    $pwshSrcDir = Join-Path $scriptDir "pwsh"
    if (-not (Test-Path -LiteralPath $pwshSrcDir -PathType Container)) {
        throw "error: app '$App' not found at: $pwshSrcDir"
    }

    $documentsDir = [Environment]::GetFolderPath("MyDocuments")
    if ([string]::IsNullOrWhiteSpace($documentsDir)) {
        throw "error: could not resolve Documents path for current user"
    }

    $pwshDestDir = Join-Path $documentsDir "PowerShell"
    Link-Path -SourcePath $pwshSrcDir -DestPath $pwshDestDir
    exit 0
}

if ($App -eq "nvim") {
    Ensure-SubmoduleReady -RepoDir $scriptDir -SubmodulePath "nvim"
}

$src = Join-Path $scriptDir $App
if (-not (Test-Path -LiteralPath $src -PathType Container)) {
    throw "error: app '$App' not found at: $src"
}

if ($App -eq "copilot") {
    $dest = Join-Path $HOME ".copilot"
} elseif ($App -eq "opencode") {
    $dest = Join-Path $HOME ".config/opencode"
} elseif ($App -eq "nvim") {
    $localAppData = [Environment]::GetFolderPath("LocalApplicationData")
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        $localAppData = Join-Path $HOME "AppData/Local"
    }
    New-Item -ItemType Directory -Path $localAppData -Force | Out-Null
    $dest = Join-Path $localAppData "nvim"
} else {
    $configHome = Get-ConfigHome
    New-Item -ItemType Directory -Path $configHome -Force | Out-Null
    $dest = Join-Path $configHome $App
}

Link-Path -SourcePath $src -DestPath $dest
