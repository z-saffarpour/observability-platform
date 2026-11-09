#Requires -Version 5.1
<#
.SYNOPSIS
  Builds one Alertmanager config from alertmanager/exporters.json.
.EXAMPLE
  .\scripts\powershell\alertmanager\Build-AlertmanagerConfig.ps1
#>
[CmdletBinding()]
param(
    [string]$SourceRoot,
    [string]$ManifestPath,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
}
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$AlertmanagerRoot = Join-Path $SourceRoot 'alertmanager'
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $AlertmanagerRoot 'exporters.json'
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $AlertmanagerRoot 'config\alertmanager.yml'
}
$ManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$OutputPath = [IO.Path]::GetFullPath($OutputPath)

function Read-Utf8Lines {
    param([Parameter(Mandatory)][string]$Path)
    $text = [IO.File]::ReadAllText($Path)
    $text = $text.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
    $list = New-Object System.Collections.Generic.List[string]
    if ($text.Length -gt 0) {
        $list.AddRange($text.Split([string[]]@("`n"), [StringSplitOptions]::None))
    }
    return $list
}

function Get-YamlSections {
    param([string[]]$Lines)
    $sections = [ordered]@{}
    $current = $null
    $buffer = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        if ($line -match '^[A-Za-z0-9_]+:\s*$') {
            if ($null -ne $current) { $sections[$current] = $buffer.ToArray() }
            $current = ($line -split ':', 2)[0]
            $buffer = New-Object System.Collections.Generic.List[string]
            $buffer.Add($line)
        }
        elseif ($null -ne $current) {
            $buffer.Add($line)
        }
    }
    if ($null -ne $current) { $sections[$current] = $buffer.ToArray() }
    return $sections
}

function Get-NormalizedBlock {
    param([string[]]$Lines)
    $kept = foreach ($line in $Lines) {
        if ($line -match '^\s*#') { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $line.TrimEnd()
    }
    return ($kept -join "`n")
}

function Split-YamlItems {
    param([string[]]$BodyLines)
    $items = New-Object System.Collections.Generic.List[string]
    $current = New-Object System.Collections.Generic.List[string]
    foreach ($line in $BodyLines) {
        if ($line -match '^  - ' -and $current.Count -gt 0) {
            $splitAt = $current.Count
            for ($i = $current.Count - 1; $i -ge 0; $i--) {
                $existing = [string]$current[$i]
                if ([string]::IsNullOrWhiteSpace($existing) -or $existing -match '^\s*#') { $splitAt = $i }
                else { break }
            }
            if ($splitAt -gt 0) {
                $head = New-Object System.Collections.Generic.List[string]
                for ($i = 0; $i -lt $splitAt; $i++) { $head.Add([string]$current[$i]) }
                $items.Add(($head.ToArray() -join "`n"))
                $kept = New-Object System.Collections.Generic.List[string]
                for ($i = $splitAt; $i -lt $current.Count; $i++) { $kept.Add([string]$current[$i]) }
                $current = $kept
            }
        }
        $current.Add($line)
    }
    if ($current.Count -gt 0) { $items.Add(($current.ToArray() -join "`n")) }
    return $items
}

function Update-ExporterText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string[]]$ReceiverNames,
        [string]$Prefix
    )
    if ([string]::IsNullOrEmpty($Prefix)) { return $Text }
    $anchors = @([regex]::Matches($Text, '(?<=\s)&([A-Za-z_][A-Za-z0-9_-]*)') |
        ForEach-Object { $_.Groups[1].Value } |
        Select-Object -Unique |
        Sort-Object { $_.Length } -Descending)
    foreach ($anchor in $anchors) {
        $Text = $Text.Replace("&$anchor", "&${Prefix}$anchor").Replace("*$anchor", "*${Prefix}$anchor")
    }
    foreach ($name in ($ReceiverNames | Sort-Object Length -Descending)) {
        if ($name -eq 'none') { continue }
        $escaped = [regex]::Escape($name)
        $replacement = "${Prefix}${name}"
        $Text = [regex]::Replace($Text, "(?<=receiver:\s)$escaped(?![\w-])", $replacement)
        $Text = [regex]::Replace($Text, "(?<=- name:\s)$escaped(?![\w-])", $replacement)
    }
    return $Text
}

function Add-JobMatcher {
    param(
        [string[]]$Lines,
        [Parameter(Mandatory)][string]$Matcher
    )
    $output = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        $output.Add($line)
        if ($line -match '^(?<lead>\s*)(?:-\s+)?(source_matchers|target_matchers):\s*$') {
            $child = $Matches['lead'].Length
            if ($line -match '^\s*-\s+') { $child += 4 } else { $child += 2 }
            $output.Add((' ' * $child) + "- $Matcher")
        }
    }
    return $output.ToArray()
}

function Get-RouteParts {
    param([string[]]$SectionLines)
    $fields = @{}
    $routes = New-Object System.Collections.Generic.List[string]
    $inRoutes = $false
    foreach ($line in $SectionLines) {
        if (-not $inRoutes) {
            if ($line -match '^  routes:\s*$') { $inRoutes = $true; continue }
            if ($line -match '^  ([A-Za-z0-9_]+):\s*(.+)$') {
                $fields[$Matches[1]] = $Matches[2].Trim()
            }
        }
        else {
            $routes.Add($line)
        }
    }
    foreach ($required in @('receiver', 'group_by', 'group_wait', 'group_interval', 'repeat_interval')) {
        if (-not $fields.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($fields[$required])) {
            throw "Exporter route is missing '$required'."
        }
    }
    if (-not $inRoutes) { throw 'Exporter route is missing routes:.' }
    return [pscustomobject]@{
        Receiver       = $fields['receiver']
        GroupBy        = $fields['group_by']
        GroupWait      = $fields['group_wait']
        GroupInterval  = $fields['group_interval']
        RepeatInterval = $fields['repeat_interval']
        Routes         = $routes.ToArray()
    }
}

function Get-ReceiverNames {
    param([string[]]$SectionLines)
    $names = New-Object System.Collections.Generic.List[string]
    foreach ($line in $SectionLines) {
        if ($line -match '^  - name:\s*(\S+)\s*$') { $names.Add($Matches[1]) }
    }
    if ($names.Count -eq 0) { throw 'Exporter receivers section has no names.' }
    return $names.ToArray()
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $manifest.exporters -or @($manifest.exporters).Count -eq 0) {
    throw "No exporters in $ManifestPath"
}

$loaded = New-Object System.Collections.Generic.List[object]
$seenNames = @{}
foreach ($entry in @($manifest.exporters)) {
    $name = [string]$entry.name
    if ($name -notmatch '^[A-Za-z0-9_-]+$') { throw "Invalid exporter name: $name" }
    if ($seenNames.ContainsKey($name)) { throw "Duplicate exporter name: $name" }
    $seenNames[$name] = $true
    $isDefault = $false
    if ($entry.PSObject.Properties.Name -contains 'default') { $isDefault = [bool]$entry.default }
    $jobRegex = ''
    if ($entry.PSObject.Properties.Name -contains 'job_regex' -and $null -ne $entry.job_regex) {
        $jobRegex = [string]$entry.job_regex
    }
    if (-not $isDefault -and [string]::IsNullOrWhiteSpace($jobRegex)) {
        throw "Exporter '$name' needs job_regex or default=true."
    }
    if ($jobRegex.Contains('"') -or $jobRegex.Contains("'")) {
        throw "Exporter '$name' job_regex must not contain quotes."
    }
    $configPath = Join-Path $AlertmanagerRoot ($entry.config -replace '/', '\')
    $templateDir = Join-Path $AlertmanagerRoot ($entry.templates -replace '/', '\')
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { throw "Config was not found: $configPath" }
    if (-not (Test-Path -LiteralPath $templateDir -PathType Container)) { throw "Templates were not found: $templateDir" }
    $yamlLines = @(Read-Utf8Lines -Path $configPath)
    if ($yamlLines.Count -eq 0) { throw "No YAML lines read from $configPath" }
    $sections = Get-YamlSections -Lines $yamlLines
    foreach ($required in @('global', 'route', 'inhibit_rules', 'receivers')) {
        if (-not $sections.Contains($required)) { throw "$configPath is missing $required." }
    }
    $receiverNames = Get-ReceiverNames -SectionLines $sections['receivers']
    $prefix = ''
    if (-not $isDefault) { $prefix = "$name-" }
    $routeText = Update-ExporterText -Text ($sections['route'] -join "`n") -ReceiverNames $receiverNames -Prefix $prefix
    $receiverText = Update-ExporterText -Text ($sections['receivers'] -join "`n") -ReceiverNames $receiverNames -Prefix $prefix
    $routeParts = Get-RouteParts -SectionLines $routeText.Split("`n")
    $loaded.Add([pscustomobject]@{
        Name           = $name
        IsDefault      = $isDefault
        JobRegex       = $jobRegex
        ConfigPath     = $configPath
        TemplateDir    = $templateDir
        Global         = $sections['global']
        Inhibit        = $sections['inhibit_rules']
        Route          = $routeParts
        Receivers      = $receiverText.Split("`n")
        ReceiverPrefix = $prefix
    })
}

$defaults = @($loaded | Where-Object { $_.IsDefault })
if ($defaults.Count -ne 1) { throw "exporters.json must contain exactly one default exporter." }
$defaultExporter = $defaults[0]
$specific = @($loaded | Where-Object { -not $_.IsDefault })
$globalText = Get-NormalizedBlock -Lines $defaultExporter.Global
foreach ($exporter in $loaded) {
    $other = Get-NormalizedBlock -Lines $exporter.Global
    if ($other -ne $globalText) {
        throw "SMTP global in '$($exporter.Name)' differs from '$($defaultExporter.Name)'. One Alertmanager has one global block."
    }
}

$excludeRegex = (@($specific | ForEach-Object { $_.JobRegex }) | Where-Object { $_ }) -join '|'
$inhibitLines = New-Object System.Collections.Generic.List[string]
$inhibitLines.Add('inhibit_rules:')
foreach ($exporter in $loaded) {
    $body = @($exporter.Inhibit | Select-Object -Skip 1)
    foreach ($itemText in @(Split-YamlItems -BodyLines $body)) {
        if ([string]::IsNullOrWhiteSpace($itemText)) { continue }
        $item = @($itemText.Split("`n"))
        $scoped = $item
        if ($itemText -notmatch 'inhibit-scope:\s*global') {
            if (-not ([string]::IsNullOrWhiteSpace($excludeRegex) -and $exporter.IsDefault)) {
                if ($exporter.IsDefault) {
                    $scoped = Add-JobMatcher -Lines $item -Matcher "job !~ `"$excludeRegex`""
                }
                else {
                    $scoped = Add-JobMatcher -Lines $item -Matcher "job =~ `"$($exporter.JobRegex)`""
                }
            }
        }
        foreach ($line in @($scoped)) { $inhibitLines.Add($line) }
    }
}

$receiverLines = New-Object System.Collections.Generic.List[string]
$receiverLines.Add('receivers:')
$seenReceivers = @{}
foreach ($exporter in $loaded) {
    $body = @($exporter.Receivers | Select-Object -Skip 1)
    foreach ($itemText in @(Split-YamlItems -BodyLines $body)) {
        if ([string]::IsNullOrWhiteSpace($itemText)) { continue }
        $item = @($itemText.Split("`n"))
        if ($itemText -notmatch '(?m)^  - name:\s*(\S+)') { throw "Receiver block in '$($exporter.Name)' has no name." }
        $receiverName = $Matches[1]
        if ($seenReceivers.ContainsKey($receiverName)) {
            if ($receiverName -eq 'none') { continue }
            throw "Duplicate receiver '$receiverName'."
        }
        $seenReceivers[$receiverName] = $true
        foreach ($line in $item) { $receiverLines.Add($line) }
    }
}

$route = $defaultExporter.Route
$routeLines = New-Object System.Collections.Generic.List[string]
$routeLines.Add('route:')
$routeLines.Add("  receiver: $($route.Receiver)")
$routeLines.Add("  group_by: $($route.GroupBy)")
$routeLines.Add("  group_wait: $($route.GroupWait)")
$routeLines.Add("  group_interval: $($route.GroupInterval)")
$routeLines.Add("  repeat_interval: $($route.RepeatInterval)")
$routeLines.Add('  routes:')
foreach ($exporter in $specific) {
    $child = $exporter.Route
    $routeLines.Add('    - matchers:')
    $routeLines.Add("        - job =~ `"$($exporter.JobRegex)`"")
    $routeLines.Add("      receiver: $($child.Receiver)")
    $routeLines.Add("      group_by: $($child.GroupBy)")
    $routeLines.Add("      group_wait: $($child.GroupWait)")
    $routeLines.Add("      group_interval: $($child.GroupInterval)")
    $routeLines.Add("      repeat_interval: $($child.RepeatInterval)")
    $routeLines.Add('      continue: false')
    $routeLines.Add('      routes:')
    foreach ($line in $child.Routes) {
        if ([string]::IsNullOrWhiteSpace($line)) { $routeLines.Add('') }
        else { $routeLines.Add("    $line") }
    }
}
foreach ($line in $route.Routes) { $routeLines.Add($line) }

$header = @(
    '# Generated by scripts/powershell/alertmanager/Build-AlertmanagerConfig.ps1.',
    '# Edit alertmanager/exporters.json and each exporter alertmanager.yml, then rerun the script.',
    '# One Alertmanager process loads this file.'
)
$outputLines = New-Object System.Collections.Generic.List[string]
foreach ($line in $header) { $outputLines.Add($line) }
$outputLines.Add('')
foreach ($line in $defaultExporter.Global) { $outputLines.Add($line) }
$outputLines.Add('')
$outputLines.Add('templates:')
$outputLines.Add('  - "templates/*.tmpl"')
$outputLines.Add('')
foreach ($line in $routeLines) { $outputLines.Add($line) }
$outputLines.Add('')
foreach ($line in $inhibitLines) { $outputLines.Add($line) }
$outputLines.Add('')
foreach ($line in $receiverLines) { $outputLines.Add($line) }
$outputLines.Add('')

$templateTarget = Join-Path (Split-Path -Parent $OutputPath) 'templates'
New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force | Out-Null
New-Item -ItemType Directory -Path $templateTarget -Force | Out-Null
Get-ChildItem -LiteralPath $templateTarget -Filter '*.tmpl' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force
$copiedTemplates = @{}
foreach ($exporter in $loaded) {
    foreach ($template in @(Get-ChildItem -LiteralPath $exporter.TemplateDir -Filter '*.tmpl' -File)) {
        if ($copiedTemplates.ContainsKey($template.Name)) {
            throw "Template name collision: $($template.Name)"
        }
        Copy-Item -LiteralPath $template.FullName -Destination (Join-Path $templateTarget $template.Name) -Force
        $copiedTemplates[$template.Name] = $exporter.Name
    }
}

$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllLines($OutputPath, $outputLines.ToArray(), $utf8)

$amtool = Join-Path $SourceRoot 'alertmanager\bin\windows-amd64\amtool.exe'
if (-not (Test-Path -LiteralPath $amtool -PathType Leaf)) {
    $amtool = Join-Path $SourceRoot 'alertmanager\bin\linux-amd64\amtool'
}
if (-not (Test-Path -LiteralPath $amtool -PathType Leaf)) {
    throw "amtool was not found under alertmanager/bin."
}
Push-Location (Split-Path -Parent $OutputPath)
try {
    & $amtool check-config $OutputPath
    if ($LASTEXITCODE -ne 0) { throw 'amtool check-config failed for the combined Alertmanager config.' }
}
finally {
    Pop-Location
}

[pscustomobject]@{
    Output     = $OutputPath
    Templates  = $templateTarget
    Exporters  = ($loaded.Name -join ', ')
    Receivers  = $seenReceivers.Count
}
