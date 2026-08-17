#Requires -Version 5.1
<#
.SYNOPSIS
  Safely uninstalls prometheus_sql_exporter from remote Windows hosts.
.DESCRIPTION
  Uses WinRM, detects ServiceBase or NSSM, stops and removes the service, creates
  a ZIP backup outside the install directory, and removes deployed files. The
  Application event source is retained by default so historical events remain readable.
.EXAMPLE
  .\Uninstall-SqlExporterRemote.ps1 -Computers SQL01 -WhatIf
.EXAMPLE
  .\Uninstall-SqlExporterRemote.ps1 -Computers SQL01 -KeepFiles
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string[]]$Computers,
    [string]$ServiceName = 'prometheus_sql_exporter',
    [string]$InstallRoot,
    [ValidateSet('Preserve','ServiceBase','NSSM')][string]$ServiceMode = 'Preserve',
    [pscredential]$RemoteCredential,
    [ValidateRange(5,600)][int]$ServiceTimeoutSec = 60,
    [switch]$KeepFiles,
    [switch]$SkipBackup,
    [switch]$RemoveEventSource
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$results = @()

foreach ($computer in @($Computers | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    $row = [ordered]@{ Computer=$computer; Mode=''; Backup=''; Service=''; Files=''; EventSource='Preserved'; Error='' }
    $session = $null
    try {
        if (-not $PSCmdlet.ShouldProcess($computer, "Uninstall $ServiceName")) { $row.Service='WhatIf'; $row.Files='WhatIf'; continue }
        $sessionArgs = @{ ComputerName=$computer; ErrorAction='Stop' }
        if ($RemoteCredential) { $sessionArgs.Credential = $RemoteCredential }
        $session = New-PSSession @sessionArgs
        $result = Invoke-Command -Session $session -ScriptBlock {
            param($Name,$RootOverride,$RequestedMode,$Timeout,$KeepDeployedFiles,$NoBackup,$DeleteEventSource)
            Set-StrictMode -Version Latest
            $ErrorActionPreference = 'Stop'
            function Get-CommandExe([string]$CommandLine) {
                if (-not $CommandLine) { return $null }
                $expanded = [Environment]::ExpandEnvironmentVariables($CommandLine.Trim())
                if ($expanded.StartsWith('"')) { return ($expanded -split '"')[1] }
                return ($expanded -split '\s+')[0]
            }
            function Wait-ServiceAbsent {
                $deadline = (Get-Date).AddSeconds($Timeout)
                while ((Get-Service -Name $Name -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 250 }
                if (Get-Service -Name $Name -ErrorAction SilentlyContinue) { throw "Service was not removed within $Timeout seconds: $Name" }
            }
            $escaped = $Name.Replace("'", "''")
            $service = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction SilentlyContinue
            $parameters = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name\Parameters"
            $application = if (Test-Path -LiteralPath $parameters) { (Get-ItemProperty -LiteralPath $parameters -Name Application -ErrorAction SilentlyContinue).Application }
            $mode = if ($application -or ($service -and (Get-CommandExe $service.PathName) -match '(?i)nssm\.exe$')) { 'NSSM' } else { 'ServiceBase' }
            if ($RequestedMode -ne 'Preserve' -and $RequestedMode -ne $mode) { throw "Requested ServiceMode '$RequestedMode' does not match installed mode '$mode'." }
            $targetExe = if ($application) { [Environment]::ExpandEnvironmentVariables($application.Trim('"')) } elseif ($service) { Get-CommandExe $service.PathName } else { $null }
            $root = $RootOverride
            if (-not $root -and $targetExe) {
                $parent = Split-Path $targetExe -Parent
                $root = if ([IO.Path]::GetFileName($parent) -ieq 'bin') { Split-Path $parent -Parent } else { $parent }
            }
            if (-not $root) { $root = 'C:\Program Files\Observability\PrometheusExporters\sql-exporter' }
            $root = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($root.TrimEnd('\')))
            if ($root -eq [IO.Path]::GetPathRoot($root)) { throw "Unsafe install root: $root" }
            $backup = $null
            if (-not $NoBackup -and (Test-Path -LiteralPath $root -PathType Container)) {
                $backupDir = Join-Path $env:ProgramData 'Observability\PrometheusExporters\uninstall-backups'
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
                $backup = Join-Path $backupDir ("{0}_{1}.zip" -f $Name,(Get-Date -Format 'yyyyMMdd_HHmmss'))
                if (Get-ChildItem -LiteralPath $root -Force | Select-Object -First 1) {
                    Compress-Archive -Path (Join-Path $root '*') -DestinationPath $backup -CompressionLevel Optimal -Force
                } else { $backup = $null }
            }
            if ($service) {
                $current = Get-Service -Name $Name -ErrorAction SilentlyContinue
                if ($current -and $current.Status -ne 'Stopped') {
                    Stop-Service -Name $Name -Force -ErrorAction Stop
                    $current.WaitForStatus('Stopped',[TimeSpan]::FromSeconds($Timeout))
                }
                $nssmExe = if ($mode -eq 'NSSM') { Get-CommandExe $service.PathName } else { $null }
                if ($mode -eq 'NSSM' -and $nssmExe -and (Test-Path -LiteralPath $nssmExe -PathType Leaf)) {
                    $output = & $nssmExe remove $Name confirm 2>&1
                    if ($LASTEXITCODE -ne 0) { throw "NSSM remove failed: $($output -join [Environment]::NewLine)" }
                } else {
                    $output = & sc.exe delete $Name 2>&1
                    if ($LASTEXITCODE -ne 0) { throw "sc.exe delete failed: $($output -join [Environment]::NewLine)" }
                }
                Wait-ServiceAbsent
            }
            if (-not $KeepDeployedFiles -and (Test-Path -LiteralPath $root)) { Remove-Item -LiteralPath $root -Recurse -Force }
            if ($DeleteEventSource) {
                $eventKey = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\$Name"
                if (Test-Path -LiteralPath $eventKey) { Remove-Item -LiteralPath $eventKey -Recurse -Force }
            }
            [pscustomobject]@{ Mode=$mode; Backup=$backup; Service='Removed'; Files=$(if ($KeepDeployedFiles) {'Preserved'} else {'Removed'}); EventSource=$(if ($DeleteEventSource) {'Removed'} else {'Preserved'}) }
        } -ArgumentList $ServiceName,$InstallRoot,$ServiceMode,$ServiceTimeoutSec,[bool]$KeepFiles,[bool]$SkipBackup,[bool]$RemoveEventSource
        foreach ($key in @('Mode','Backup','Service','Files','EventSource')) { $row[$key] = $result.$key }
    } catch { $row.Error = $_.Exception.Message }
    finally {
        if ($session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        $results += [pscustomobject]$row
    }
}

$results | Format-Table -AutoSize
if (@($results | Where-Object Error).Count) { exit 1 }
