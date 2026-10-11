#Requires -Version 5.1
<#
.SYNOPSIS
  HTTP listener that turns an Alertmanager webhook into one SMS per owner.
.DESCRIPTION
  Accepts POST / , /sendsms, and /alertmanager. Owner is taken from the
  ?owner= query string, then labels.owner, then commonLabels.owner. Phone
  numbers come from the phones map: one string, a comma-separated string, or
  a JSON array. One BatchSendSms call carries every number for that owner.
  language is en or fa; omitted language stays en. fa uses summary_fa when
  that annotation exists. The API key and phone numbers are never logged.
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

function Get-SmsPhoneItems {
    param($Value, [string]$Owner)
    if ($null -eq $Value) { return @() }
    if ($Value -is [string]) {
        return @($Value.Split(@(',', ';'), [StringSplitOptions]::RemoveEmptyEntries))
    }
    $isList = $Value -is [Array] -or $Value -is [Collections.IList]
    if (-not $isList) {
        throw "phones.$Owner must be a string or an array of strings."
    }
    foreach ($item in @($Value)) {
        if ($item -isnot [string]) {
            throw "phones.$Owner must be a string or an array of strings."
        }
    }
    return @($Value)
}

function Get-ConfigPhones {
    param($Phones, [string]$Owner)
    if (-not $Phones -or [string]::IsNullOrWhiteSpace($Owner)) { return @() }
    $property = $Phones.PSObject.Properties[$Owner]
    if (-not $property) { return @() }
    $seen = @{}
    $phones = New-Object Collections.Generic.List[string]
    foreach ($item in @(Get-SmsPhoneItems -Value $property.Value -Owner $Owner)) {
        $phone = ([string]$item).Trim()
        if ([string]::IsNullOrWhiteSpace($phone) -or $phone -eq 'CHANGE_ME') { continue }
        if ($seen.ContainsKey($phone)) { continue }
        $seen[$phone] = $true
        $phones.Add($phone)
    }
    return @($phones.ToArray())
}

function Resolve-AlertOwner {
    param($Alert, $Notification, [string]$QueryOwner)
    if (-not [string]::IsNullOrWhiteSpace($QueryOwner)) { return $QueryOwner }
    $fromAlert = Get-NotePropertyValue -Object $Alert.labels -Name 'owner'
    if ($fromAlert) { return $fromAlert }
    Get-NotePropertyValue -Object $Notification.commonLabels -Name 'owner'
}

function Resolve-SmsLanguage {
    param($Config)
    $property = $Config.PSObject.Properties['language']
    if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return 'en' }
    $language = ([string]$property.Value).Trim().ToLowerInvariant()
    if ($language -notin @('en', 'fa')) {
        throw "language must be en or fa. Current value: $language"
    }
    $language
}

function ConvertFrom-SmsCodePoint {
    param([Parameter(Mandatory)][string]$HexWords)
    -join ($HexWords.Split(' ') | ForEach-Object { [char][Convert]::ToInt32($_, 16) })
}

function Get-SmsLabels {
    param([Parameter(Mandatory)][string]$Language)
    if ($Language -eq 'fa') {
        return @{
            AlertName = ConvertFrom-SmsCodePoint '0646 0627 0645 0020 0647 0634 062F 0627 0631'
            Instance  = ConvertFrom-SmsCodePoint '0633 0631 0648 0631'
            Database  = ConvertFrom-SmsCodePoint '062F 06CC 062A 0627 0628 06CC 0633'
            Summary   = ConvertFrom-SmsCodePoint '0634 0631 062D'
            AlertAt   = ConvertFrom-SmsCodePoint '0632 0645 0627 0646'
        }
    }
    return @{
        AlertName = 'Alert Name'
        Instance  = 'Instance'
        Database  = 'Database'
        Summary   = 'Summary'
        AlertAt   = 'Alert At'
    }
}

function Get-AlertText {
    param($Alert, [Parameter(Mandatory)][string]$Language, [Parameter(Mandatory)][hashtable]$SmsLabels)
    $labels = $Alert.labels
    $annotations = $Alert.annotations
    $name = Get-NotePropertyValue -Object $labels -Name 'alertname'
    $instance = Get-NotePropertyValue -Object $labels -Name 'instance'
    $database = Get-NotePropertyValue -Object $labels -Name 'db'
    $summary = $null
    if ($Language -eq 'fa') {
        $summary = Get-NotePropertyValue -Object $annotations -Name 'summary_fa'
    }
    if (-not $summary) {
        $summary = Get-NotePropertyValue -Object $annotations -Name 'summary'
    }
    $when = [string]$Alert.startsAt
    try { $when = (Get-Date $Alert.startsAt -Format 'yyyy-MM-dd HH:mm:ss') } catch { }
    $text = "$($SmsLabels.AlertName) : $name.`n$($SmsLabels.Instance) : $instance.`n"
    if ($database) { $text += "$($SmsLabels.Database) : $database.`n" }
    $text + "$($SmsLabels.Summary) : $summary.`n$($SmsLabels.AlertAt) : $when.`n"
}

if ($MyInvocation.InvocationName -eq '.') { return }

$ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
$config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$prefix = [string]$config.listenPrefix
if ($prefix -notmatch '^http://(127\.0\.0\.1|localhost):\d+/$') {
    throw "listenPrefix must be a loopback HTTP prefix, for example http://127.0.0.1:49177/"
}

if (-not $config.phones) { throw 'The SMS config must contain a phones map.' }
foreach ($phoneProperty in @($config.phones.PSObject.Properties)) {
    [void](Get-SmsPhoneItems -Value $phoneProperty.Value -Owner $phoneProperty.Name)
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$smsLanguage = Resolve-SmsLanguage -Config $config
$smsLabels = Get-SmsLabels -Language $smsLanguage
$listener.Start()
Write-SmsLog "SMS gateway listening on $prefix"
Write-SmsLog "SMS language is $smsLanguage"

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
                        $byOwner[$owner].Add((Get-AlertText -Alert $alert -Language $smsLanguage -SmsLabels $smsLabels)) | Out-Null
                    }
                }
                if ($byOwner.Count -eq 0) {
                    $body = 'no firing alerts'
                }
                else {
                    $sent = 0
                    $missing = New-Object System.Collections.Generic.List[string]
                    foreach ($owner in @($byOwner.Keys)) {
                        $phones = @(Get-ConfigPhones -Phones $config.phones -Owner $owner)
                        if ($phones.Count -eq 0) {
                            Write-SmsLog "No phone configured for owner '$owner'. SMS was not sent."
                            $missing.Add($owner) | Out-Null
                            continue
                        }
                        $text = $byOwner[$owner] -join "`n"
                        Write-SmsLog ("Sending {0} firing alert(s) for owner {1} to {2} phone(s)" -f $byOwner[$owner].Count, $owner, $phones.Count)
                        $messageBody = ConvertTo-JsonString $text
                        $model = foreach ($phone in $phones) {
                            '{"phoneNumber":"' + (ConvertTo-JsonString $phone) + '","messageBody":"' + $messageBody + '"}'
                        }
                        $json = '{"model":[' + ($model -join ',') + ']}'
                        $headers = @{
                            'Content-Type' = 'application/json; charset=utf-8'
                            [string]$config.authorizationHeader = [string]$config.authorizationValue
                        }
                        $jsonBytes = [Text.Encoding]::UTF8.GetBytes($json)
                        $apiResponse = Invoke-RestMethod -Uri ([string]$config.smsEndpoint) -Method Post -Headers $headers -Body $jsonBytes -TimeoutSec 30
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
