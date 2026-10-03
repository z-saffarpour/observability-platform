#Requires -Version 5.1
<#
.SYNOPSIS
  Standard ProgramData paths for SSAS runtime files (XEL, secrets, audit).
#>
function Get-SsasProgramDataRoot {
    Join-Path $env:ProgramData 'Observability\SSAS'
}

function Get-SsasXEventsDirectory {
    Join-Path (Get-SsasProgramDataRoot) 'xevents'
}

function Get-SsasSecretsDirectory {
    Join-Path (Get-SsasProgramDataRoot) 'secrets'
}

function Get-SsasAuditDirectory {
    Join-Path (Get-SsasProgramDataRoot) 'audit'
}

function Get-SsasDefaultXelPath {
    Join-Path (Get-SsasXEventsDirectory) '*.xel'
}

function Get-SsasDefaultReadOnlyProbePath {
    Join-Path (Get-SsasSecretsDirectory) 'readonly-probe.connectionstring'
}

function Get-SsasDefaultAuditLogPath {
    Join-Path (Get-SsasAuditDirectory) 'ssas-security-audit.jsonl'
}

function Ensure-SsasProgramDataDirectories {
    foreach ($directory in @(
        (Get-SsasProgramDataRoot),
        (Get-SsasXEventsDirectory),
        (Join-Path (Get-SsasXEventsDirectory) 'archive'),
        (Get-SsasSecretsDirectory),
        (Get-SsasAuditDirectory),
        (Join-Path (Get-SsasAuditDirectory) 'archive')
    )) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
}
