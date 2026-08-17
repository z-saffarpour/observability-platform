#Requires -Version 5.1
<#
.SYNOPSIS
  Converts SSAS Extended Event files into cumulative Prometheus counters and SIEM JSONL.
.NOTES
  Requires the SqlServer PowerShell module (Read-SqlXEvent). User/IP/application details
  are written only to SiemOutputPath and never become Prometheus labels.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string[]]$XelPath,
  [string]$OutputPath=(Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'textfile_inputs\ssas-xevents.prom'),
  [string]$StatePath=(Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'state\ssas-xevents-state.json'),
  [string]$SiemOutputPath=(Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'Log\ssas-security-audit.jsonl')
)
$ErrorActionPreference='Stop';$inv=[Globalization.CultureInfo]::InvariantCulture
function Esc([object]$v){if($null-eq$v){return ''};([string]$v).Replace('\','\\').Replace("`n",'\n').Replace('"','\"')}
function Labels([hashtable]$h){if(-not$h.Count){return ''};'{'+(($h.Keys|Sort-Object|ForEach-Object{"$_=`"$(Esc $h[$_])`""})-join',')+'}'}
function Metric($lines,[string]$name,[double]$value,[hashtable]$labels=@{}){$lines.Add("$name$(Labels $labels) $($value.ToString('R',$inv))")}
function Get-EventValue($event,[string[]]$names){
  foreach($name in $names){
    $p=$event.PSObject.Properties[$name];if($p -and $null-ne$p.Value){return $p.Value}
    try{$field=$event.Fields|Where-Object{$_.Name -ieq $name}|Select-Object -First 1;if($field){return $field.Value}}catch{}
    try{$action=$event.Actions|Where-Object{$_.Name -ieq $name}|Select-Object -First 1;if($action){return $action.Value}}catch{}
  };$null
}
function Unix($value){try{([DateTimeOffset]([datetime]$value).ToUniversalTime()).ToUnixTimeSeconds()}catch{0}}

$defaults=[ordered]@{logins=0L;logouts=0L;login_failures=0L;permission_changes=0L;admin_operations=0L;privileged_access_changes=0L;server_restarts=0L;processing_successes=0L;processing_failures=0L;last_processing_timestamp=0L;last_processing_duration_ms=0.0;last_backup_timestamp=0L;queries=0L;query_errors=0L;query_cancellations=0L;query_duration_ms=0.0;directquery_failures=0L;last_event_timestamp=0L}
$state=[ordered]@{counters=$defaults;files=@{}}
if(Test-Path $StatePath){try{$old=Get-Content -Raw $StatePath|ConvertFrom-Json;foreach($p in $defaults.Keys){if($null-ne$old.counters.$p){$state.counters[$p]=$old.counters.$p}};foreach($p in $old.files.PSObject.Properties){$state.files[$p.Name]=[int64]$p.Value}}catch{}}
$errors=0;$newEvents=0
try{Import-Module SqlServer -ErrorAction Stop}catch{$errors++}
if(Get-Command Read-SqlXEvent -ErrorAction SilentlyContinue){
  foreach($pattern in $XelPath){foreach($file in @(Get-ChildItem $pattern -File -ErrorAction SilentlyContinue)){
    $cursor=if($state.files.ContainsKey($file.FullName)){[int64]$state.files[$file.FullName]}else{0L};$max=$cursor
    try{foreach($event in @(Read-SqlXEvent -FileName $file.FullName -ErrorAction Stop)){
      $timestamp=Unix (Get-EventValue $event @('Timestamp','timestamp'));if($timestamp -le $cursor){continue};if($timestamp -gt $max){$max=$timestamp};if($timestamp -gt $state.counters.last_event_timestamp){$state.counters.last_event_timestamp=$timestamp};$newEvents++
      $name=[string](Get-EventValue $event @('Name','name','EventName'));$text=[string](Get-EventValue $event @('TextData','text_data','statement'));$duration=[double](Get-EventValue $event @('Duration','duration','duration_milliseconds'))
      switch -Regex ($name){
        'Audit\s*Login'{$state.counters.logins++;if($text -match '(?i)(fail|denied|error)'){$state.counters.login_failures++}}
        'Audit\s*Logout'{$state.counters.logouts++}
        'Audit\s*Server\s*Starts'{$state.counters.server_restarts++}
        'Audit\s*Object\s*Permission'{$state.counters.permission_changes++;$state.counters.privileged_access_changes++}
        'Audit\s*Admin\s*Operations'{$state.counters.admin_operations++;if($text -match '(?i)backup|image\s*save'){$state.counters.last_backup_timestamp=$timestamp}}
        '^CommandEnd$'{if($text -match '(?i)process|refresh'){$state.counters.processing_successes++;$state.counters.last_processing_timestamp=$timestamp;$state.counters.last_processing_duration_ms=$duration}}
        'Error'{if($text -match '(?i)process|refresh'){$state.counters.processing_failures++};if($text -match '(?i)login|authentication'){$state.counters.login_failures++};if($text -match '(?i)directquery|direct query'){$state.counters.directquery_failures++}}
        'QueryEnd'{$state.counters.queries++;$state.counters.query_duration_ms+=$duration;if($text -match '(?i)cancel'){$state.counters.query_cancellations++};if($text -match '(?i)error|fail'){$state.counters.query_errors++}}
      }
      $detail=[ordered]@{timestamp=(Get-EventValue $event @('Timestamp','timestamp'));event=$name;user=(Get-EventValue $event @('CurrentUser','NTUserName','username'));client_ip=(Get-EventValue $event @('ClientHostName','client_hostname','client_ip'));application=(Get-EventValue $event @('ApplicationName','client_app_name'));database=(Get-EventValue $event @('DatabaseName','database_name'));duration_ms=$duration;text=$text;source_file=$file.FullName}
      $siemDir=Split-Path $SiemOutputPath -Parent;New-Item $siemDir -ItemType Directory -Force|Out-Null;Add-Content -LiteralPath $SiemOutputPath -Value ($detail|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8
    };$state.files[$file.FullName]=$max}catch{$errors++}
  }}
}
$lines=[Collections.Generic.List[string]]::new();$c=$state.counters
Metric $lines 'ssas_logins_total' $c.logins;Metric $lines 'ssas_logouts_total' $c.logouts;Metric $lines 'ssas_login_failures_total' $c.login_failures
Metric $lines 'ssas_permission_changes_total' $c.permission_changes;Metric $lines 'ssas_admin_operations_total' $c.admin_operations;Metric $lines 'ssas_privileged_access_changes_total' $c.privileged_access_changes
Metric $lines 'ssas_xevent_server_restarts_total' $c.server_restarts;Metric $lines 'ssas_processing_successes_total' $c.processing_successes;Metric $lines 'ssas_processing_failures_total' $c.processing_failures
Metric $lines 'ssas_last_successful_processing_timestamp_seconds' $c.last_processing_timestamp;Metric $lines 'ssas_last_processing_duration_seconds' ([double]$c.last_processing_duration_ms/1000);Metric $lines 'ssas_last_backup_timestamp_seconds' $c.last_backup_timestamp
Metric $lines 'ssas_queries_total' $c.queries;Metric $lines 'ssas_query_errors_total' $c.query_errors;Metric $lines 'ssas_query_cancellations_total' $c.query_cancellations;Metric $lines 'ssas_query_duration_seconds_total' ([double]$c.query_duration_ms/1000)
Metric $lines 'ssas_directquery_failures_total' $c.directquery_failures
Metric $lines 'ssas_xevent_events_processed' $newEvents;Metric $lines 'ssas_xevent_collector_errors' $errors;Metric $lines 'ssas_xevent_last_event_timestamp_seconds' $c.last_event_timestamp
$outDir=Split-Path $OutputPath -Parent;$stateDir=Split-Path $StatePath -Parent;New-Item $outDir,$stateDir -ItemType Directory -Force|Out-Null
$tmp=Join-Path $outDir ('.ssas-xevent.'+[guid]::NewGuid().ToString('N')+'.tmp');[IO.File]::WriteAllLines($tmp,$lines,[Text.UTF8Encoding]::new($false));Move-Item $tmp $OutputPath -Force
$state|ConvertTo-Json -Depth 8|Set-Content $StatePath -Encoding UTF8
if($errors){Write-Warning "SSAS xEvent collector completed with $errors error(s)."}
