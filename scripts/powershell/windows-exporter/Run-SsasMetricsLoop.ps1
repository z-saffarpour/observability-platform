#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$EventSource = 'prometheus_windows_ssas',
    [Parameter(Mandatory)][string]$CollectorScript,
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateRange(1, 60)][int]$IntervalMinutes = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function Write-ServiceEvent {
    param([string]$Message, [ValidateSet('Information','Warning','Error')][string]$Type, [int]$EventId)
    try {
        Write-EventLog -LogName Application -Source $EventSource -EntryType $Type -EventId $EventId -Message $Message -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to write Application event for ${EventSource}: $($_.Exception.Message)"
    }
}

foreach ($requiredFile in @($CollectorScript, $ConfigPath)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required SSAS service file was not found: $requiredFile"
    }
}

Write-ServiceEvent -Type Information -EventId 1000 -Message "SSAS metrics service started. IntervalMinutes=$IntervalMinutes; ConfigPath=$ConfigPath"

while ($true) {
    $started = Get-Date
    try {
        & $CollectorScript -ConfigPath $ConfigPath
        if (-not $?) {
            Write-ServiceEvent -Type Error -EventId 1002 -Message 'One or more SSAS collectors failed.'
            Write-Error 'One or more SSAS collectors failed.'
        }
    }
    catch {
        Write-ServiceEvent -Type Error -EventId 1003 -Message $_.Exception.ToString()
        Write-Error $_
    }

    $elapsed = (Get-Date) - $started
    $remaining = [TimeSpan]::FromMinutes($IntervalMinutes) - $elapsed
    if ($remaining.TotalMilliseconds -gt 0) {
        Start-Sleep -Milliseconds ([int][Math]::Min($remaining.TotalMilliseconds, [int]::MaxValue))
    }
}
