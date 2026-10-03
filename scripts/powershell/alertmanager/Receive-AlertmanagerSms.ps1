#Requires -Version 5.1
<#
.SYNOPSIS
  HTTP listener that turns an Alertmanager webhook into one SMS per owner.
.DESCRIPTION
  Accepts POST / , /sendsms, and /alertmanager. Owner is taken from the
  ?owner= query string, then labels.owner, then commonLabels.owner. The phone
  number comes from the phones map in the config file. The API key is never logged.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-SmsLog([string]$Message) {
    Write-Output ("{0} {1}" -f (Get-Date -Format o), $Message)
}

function ConvertTo-JsonString([string]$Value) {
    if ($null -eq $Value) { return '' }
    ($Value -replace '\\', '\\' -replace '"', '\"' -replace "`r", '\r' -replace "`n", '\n' -replace "`t", '\t')
}

function Get-NotePropertyValue {
    param($Object, [string]$Name)
    if (-not $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return $null }
    [string]$property.Value
}

function Get-ConfigPhone {
    param($Phones, [string]$Owner)
    if (-not $Phones -or [string]::IsNullOrWhiteSpace($Owner)) { return $null }
    $property = $Phones.PSObject.Properties[$Owner]
    if (-not $property) { return $null }
    if ([string]::IsNullOrWhiteSpace([string]$property.Value) -or [string]$property.Value -eq 'CHANGE_ME') { return $null }
    [string]$property.Value
}

function Resolve-AlertOwner {
    param($Alert, $Notification, [string]$QueryOwner)
    if (-not [string]::IsNullOrWhiteSpace($QueryOwner)) { return $QueryOwner }
    $fromAlert = Get-NotePropertyValue -Object $Alert.labels -Name 'owner'
    if ($fromAlert) { return $fromAlert }
    Get-NotePropertyValue -Object $Notification.commonLabels -Name 'owner'
}

function Get-AlertText {
    param($Alert)
    $labels = $Alert.labels
    $annotations = $Alert.annotations
    $name = Get-NotePropertyValue -Object $labels -Name 'alertname'
    $instance = Get-NotePropertyValue -Object $labels -Name 'instance'
    $summary = Get-NotePropertyValue -Object $annotations -Name 'summary'
    $when = [string]$Alert.startsAt
    try { $when = (Get-Date $Alert.startsAt -Format 'yyyy-MM-dd HH:mm:ss') } catch { }
    "Alert Name : $name.`nInstance : $instance.`nSummary : $summary.`nAlert At : $when.`n"
}

$ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$prefix = [string]$config.listenPrefix
if ($prefix -notmatch '^http://(127\.0\.0\.1|localhost):\d+/$') {
    throw "listenPrefix must be a loopback HTTP prefix, for example http://127.0.0.1:49177/"
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-SmsLog "SMS gateway listening on $prefix"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $response.StatusCode = 200
        $body = ''
        try {
            $path = $request.Url.LocalPath
            if ($request.HttpMethod -eq 'GET' -and $path -in @('/', '/metrics')) {
                $body = "alertmanager_sms_gateway_up 1"
                $response.ContentType = 'text/plain; version=0.0.4; charset=utf-8'
            }
            elseif ($request.HttpMethod -eq 'POST' -and $path -in @('/', '/sendsms', '/alertmanager')) {
                $reader = [IO.StreamReader]::new($request.InputStream, [Text.Encoding]::UTF8)
                try { $payloadText = $reader.ReadToEnd() }
                finally { $reader.Dispose() }
                $payload = $payloadText | ConvertFrom-Json
                $queryOwner = Get-NotePropertyValue -Object $request.QueryString -Name 'owner'
                if (-not $queryOwner) { $queryOwner = [string]$request.QueryString['owner'] }
                $byOwner = @{}
                foreach ($notification in @($payload)) {
                    if ((Get-NotePropertyValue -Object $notification -Name 'status') -ne 'firing') { continue }
                    foreach ($alert in @($notification.alerts)) {
                        if ((Get-NotePropertyValue -Object $alert -Name 'status') -ne 'firing') { continue }
                        $owner = Resolve-AlertOwner -Alert $alert -Notification $notification -QueryOwner $queryOwner
                        if ([string]::IsNullOrWhiteSpace($owner)) { $owner = 'unknown' }
                        if (-not $byOwner.ContainsKey($owner)) { $byOwner[$owner] = New-Object System.Collections.Generic.List[string] }
                        $byOwner[$owner].Add((Get-AlertText -Alert $alert)) | Out-Null
                    }
                }
                if ($byOwner.Count -eq 0) {
                    $body = 'no firing alerts'
                }
                else {
                    $sent = 0
                    $missing = New-Object System.Collections.Generic.List[string]
                    foreach ($owner in @($byOwner.Keys)) {
                        $phone = Get-ConfigPhone -Phones $config.phones -Owner $owner
                        if (-not $phone) {
                            Write-SmsLog "No phone configured for owner '$owner'. SMS was not sent."
                            $missing.Add($owner) | Out-Null
                            continue
                        }
                        $text = $byOwner[$owner] -join "`n"
                        Write-SmsLog ("Sending {0} firing alert(s) for owner {1}" -f $byOwner[$owner].Count, $owner)
                        $json = '{"model":[{"phoneNumber":"' + (ConvertTo-JsonString $phone) + '","messageBody":"' + (ConvertTo-JsonString $text) + '"}]}'
                        $headers = @{
                            'Content-Type' = 'application/json'
                            [string]$config.authorizationHeader = [string]$config.authorizationValue
                        }
                        $apiResponse = Invoke-RestMethod -Uri ([string]$config.smsEndpoint) -Method Post -Headers $headers -Body $json -TimeoutSec 30
                        $body = $apiResponse | ConvertTo-Json -Compress -Depth 6
                        $sent++
                        Write-SmsLog "SMS API call completed for owner $owner."
                    }
                    if ($sent -eq 0) { $body = 'no phone for owner' }
                    elseif ($missing.Count -gt 0) { $body = "sent $sent; missing phone for $($missing -join ',')" }
                }
                $response.ContentType = 'text/plain; charset=utf-8'
            }
            else {
                $response.StatusCode = 404
                $body = 'Page not found'
            }
        }
        catch {
            Write-SmsLog $_.Exception.Message
            $response.StatusCode = 500
            $body = 'Internal Server Error'
        }
        $statusCode = $response.StatusCode
        $buffer = [Text.Encoding]::UTF8.GetBytes([string]$body)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
        $remote = if ($request.RemoteEndPoint) { $request.RemoteEndPoint.ToString() } else { '-' }
        Write-SmsLog "$remote `"$($request.HttpMethod) $($request.Url.LocalPath)`" $statusCode"
    }
}
finally {
    Write-SmsLog 'Stopping.'
    $listener.Stop()
    $listener.Close()
}
