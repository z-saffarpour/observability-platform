#Requires -Version 5.1
<#
.SYNOPSIS
  Helpers for exporter web.listen-address and web-config.yml Basic Auth deployment.
#>
Set-StrictMode -Version Latest

function Test-ObservabilityListenAddress {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Address
    )

    if ([string]::IsNullOrWhiteSpace($Address)) {
        throw 'ListenAddress cannot be empty when specified. Examples: ":9399", "0.0.0.0:9399", "127.0.0.1:9182".'
    }

    if ($Address -notmatch '^(\[[0-9a-fA-F:]+\]|[^\s:\[\]]+|\*|\d{1,3}(?:\.\d{1,3}){3})?:\d+$') {
        throw "Invalid ListenAddress '$Address'. Use host:port or :port (for example ':9399' or '127.0.0.1:9182')."
    }
}

function ConvertTo-ObservabilityPlainText {
    param([Security.SecureString]$SecureString)
    if ($null -eq $SecureString) { return $null }
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function New-ObservabilityBcryptHash {
    param(
        [Parameter(Mandatory)][string]$Password,
        [ValidateRange(4, 31)][int]$Cost = 12
    )

    if ([string]::IsNullOrEmpty($Password)) {
        throw 'Basic Auth password cannot be empty.'
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        throw 'Hashing -BasicAuthPassword requires Python with the bcrypt module. Pass -BasicAuthHash instead, or install Python and run: pip install bcrypt'
    }

    $pyScript = @"
import bcrypt
import sys
password = sys.stdin.buffer.read()
print(bcrypt.hashpw(password, bcrypt.gensalt(rounds=$Cost)).decode('utf-8'))
"@
    $hash = $Password | & $python.Source -c $pyScript 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "bcrypt hash generation failed: $($hash -join [Environment]::NewLine)"
    }

    $hashText = ($hash | Out-String).Trim()
    if ($hashText -notmatch '^\$2[aby]\$\d{2}\$') {
        throw "bcrypt hash generation returned an unexpected value: $hashText"
    }

    return $hashText
}

function Resolve-ObservabilityBasicAuthUsers {
    param(
        [string]$Username,
        [SecureString]$Password,
        [string]$Hash
    )

    $hasUser = -not [string]::IsNullOrWhiteSpace($Username)
    $hasHash = -not [string]::IsNullOrWhiteSpace($Hash)
    $hasPassword = $null -ne $Password

    if (-not $hasUser -and ($hasHash -or $hasPassword)) {
        throw 'BasicAuthUsername is required when -BasicAuthHash or -BasicAuthPassword is specified.'
    }

    if ($hasUser -and -not $hasHash -and -not $hasPassword) {
        throw 'Specify -BasicAuthHash or -BasicAuthPassword when BasicAuthUsername is set.'
    }

    if ($hasHash -and $hasPassword) {
        throw 'Use either -BasicAuthHash or -BasicAuthPassword, not both.'
    }

    if (-not $hasUser) {
        return $null
    }

    if (-not $hasHash) {
        $plain = ConvertTo-ObservabilityPlainText -SecureString $Password
        $Hash = New-ObservabilityBcryptHash -Password $plain
    }
    elseif ($Hash -notmatch '^\$2[aby]\$\d{2}\$') {
        throw "BasicAuthHash does not look like a bcrypt hash: $Hash"
    }

    return @{ $Username.Trim() = $Hash.Trim() }
}

function Format-ObservabilityBasicAuthYamlBlock {
    param([Parameter(Mandatory)][hashtable]$BasicAuthUsers)

    if ($BasicAuthUsers.Count -eq 0) {
        return 'basic_auth_users: {}'
    }

    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('basic_auth_users:')
    foreach ($entry in ($BasicAuthUsers.GetEnumerator() | Sort-Object Name)) {
        [void]$lines.Add(('  {0}: {1}' -f $entry.Key, $entry.Value))
    }
    return ($lines -join [Environment]::NewLine)
}

function Set-ObservabilityWebConfigBasicAuth {
    param(
        [Parameter(Mandatory)][string]$Content,
        [AllowNull()][hashtable]$BasicAuthUsers
    )

    $block = Format-ObservabilityBasicAuthYamlBlock -BasicAuthUsers $(if ($null -eq $BasicAuthUsers) { @{} } else { $BasicAuthUsers })
    $lines = [regex]::Split($Content, '\r?\n')
    $output = New-Object System.Collections.Generic.List[string]
    $replacing = $false

    foreach ($line in $lines) {
        if ($line -match '^basic_auth_users:\s*') {
            if (-not $replacing) {
                foreach ($blockLine in ($block -split '\r?\n')) { [void]$output.Add($blockLine) }
                $replacing = $true
            }
            continue
        }

        if ($replacing) {
            if ($line -match '^\s+\S') { continue }
            $replacing = $false
        }

        [void]$output.Add($line)
    }

    if (-not (($output -join [Environment]::NewLine) -match '(?m)^basic_auth_users:\s*')) {
        if ($output.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($output[$output.Count - 1])) {
            [void]$output.Add('')
        }
        foreach ($blockLine in ($block -split '\r?\n')) { [void]$output.Add($blockLine) }
    }

    return (($output -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}

function New-ObservabilityWebConfigDeployFile {
    param(
        [Parameter(Mandatory)][string]$TemplatePath,
        [Parameter(Mandatory)][string]$OutputPath,
        [AllowNull()][hashtable]$BasicAuthUsers
    )

    if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) {
        throw "web-config template was not found: $TemplatePath"
    }

    $content = Get-Content -LiteralPath $TemplatePath -Raw
    if ($null -ne $BasicAuthUsers) {
        $content = Set-ObservabilityWebConfigBasicAuth -Content $content -BasicAuthUsers $BasicAuthUsers
    }

    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -Path $outDir -ItemType Directory -Force | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($OutputPath, $content, $utf8)
    return $OutputPath
}

function Resolve-ObservabilityWebConfigDeployment {
    param(
        [Parameter(Mandatory)][string]$TemplatePath,
        [string]$WebConfigPath,
        [string]$BasicAuthUsername,
        [SecureString]$BasicAuthPassword,
        [string]$BasicAuthHash
    )

    if (-not [string]::IsNullOrWhiteSpace($WebConfigPath)) {
        if (-not (Test-Path -LiteralPath $WebConfigPath -PathType Leaf)) {
            throw "WebConfigPath was not found: $WebConfigPath"
        }
        if (-not [string]::IsNullOrWhiteSpace($BasicAuthUsername) -or $null -ne $BasicAuthPassword -or -not [string]::IsNullOrWhiteSpace($BasicAuthHash)) {
            throw 'Use either -WebConfigPath or Basic Auth parameters (-BasicAuthUsername / -BasicAuthHash), not both.'
        }
        return (Resolve-Path -LiteralPath $WebConfigPath).Path
    }

    $authSpecified = (-not [string]::IsNullOrWhiteSpace($BasicAuthUsername)) `
        -or ($null -ne $BasicAuthPassword) `
        -or (-not [string]::IsNullOrWhiteSpace($BasicAuthHash))

    if (-not $authSpecified) {
        return (Resolve-Path -LiteralPath $TemplatePath).Path
    }

    $users = Resolve-ObservabilityBasicAuthUsers -Username $BasicAuthUsername -Password $BasicAuthPassword -Hash $BasicAuthHash
    $outputPath = Join-Path $env:TEMP ("observability-web-config-{0}.yml" -f [guid]::NewGuid().ToString('N'))
    New-ObservabilityWebConfigDeployFile -TemplatePath $TemplatePath -OutputPath $outputPath -BasicAuthUsers $users | Out-Null
    return $outputPath
}

function Get-ObservabilityExporterAppParameters {
    param(
        [Parameter(Mandatory)][string]$ConfigFile,
        [Parameter(Mandatory)][string]$WebConfigFile,
        [Parameter(Mandatory)][string]$ListenAddress
    )

    return ('--config.file="{0}" --web.listen-address="{1}" --web.config.file="{2}"' -f $ConfigFile, $ListenAddress, $WebConfigFile)
}

function Resolve-ObservabilityListenAddressForUpgrade {
    param(
        [string]$RequestedAddress,
        [string]$CurrentAppParameters,
        [string]$CurrentServicePath,
        [string]$DefaultAddress
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedAddress)) {
        Test-ObservabilityListenAddress -Address $RequestedAddress
        return $RequestedAddress
    }

    $listenSource = if ($CurrentAppParameters) { $CurrentAppParameters } else { $CurrentServicePath }
    if (-not [string]::IsNullOrWhiteSpace($listenSource)) {
        return (Get-ObservabilityListenAddressFromAppParameters -AppParameters $listenSource -Default $DefaultAddress)
    }

    return $DefaultAddress
}
