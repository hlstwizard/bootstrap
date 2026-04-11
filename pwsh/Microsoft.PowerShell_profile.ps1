$env:Path += "$HOME\\bin;"
$env:GNUPGHOME = Join-Path $env:APPDATA "gnupg"

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

New-Alias which Get-Command -Force
New-Alias cat Get-Content -Force
New-Alias dig Resolve-DnsName -Force

function Initialize-SshAgent {
    $agentService = Get-Service -Name "ssh-agent" -ErrorAction SilentlyContinue
    if (-not $agentService) {
        Write-Host "warn: OpenSSH ssh-agent service is not available on this system"
        return
    }

    if ($agentService.Status -ne "Running") {
        try {
            Start-Service -Name "ssh-agent" -ErrorAction Stop
        } catch {
            Write-Host "warn: failed to start ssh-agent service: $($_.Exception.Message)"
            return
        }
    }

    $knownKeys = @(
        (Join-Path $HOME ".ssh/id_ed25519"),
        (Join-Path $HOME ".ssh/h.l.s.t"),
        (Join-Path $HOME ".ssh/hlstwizard")
    )

    $loadedOutput = (& ssh-add -l 2>$null | Out-String)

    foreach ($keyPath in $knownKeys) {
        if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
            continue
        }

        if ($loadedOutput -like "*$keyPath*") {
            continue
        }

        try {
            & ssh-add $keyPath | Out-Null
        } catch {
            Write-Host "warn: failed to add key to ssh-agent: $keyPath"
        }
    }
}

Initialize-SshAgent

$azAccount = az account show --query id -o tsv
$env:AZ_ACCOUNT_ID = $azAccount

& "$HOME\\miniconda3\\shell\\condabin\\conda-hook.ps1"
$env:PATH += ";$HOME\\.local\\bin"
