#Requires -Version 5.1
<#
.SYNOPSIS
  Exports the supported SSAS performance counter groups with stable Prometheus aliases.
.DESCRIPTION
  Object prefixes vary by SSAS version and named instance (MSOLAP/MSASxx). This script
  discovers them locally. It exports a bounded generic series for every counter in the
  selected official groups and stable aliases for operational dashboards and alerts.
#>
[CmdletBinding()]
param(
  [string]$OutputPath=(Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'textfile_inputs\ssas-performance.prom'),
  [string[]]$CounterGroup=@('Connection','Cache','Locks','Memory','Processing','Processing Aggregations','Processing Indexes','Storage Engine Query','Threads','Reliability'),
  [ValidateRange(1,60)][int]$SampleIntervalSeconds=1
)
$ErrorActionPreference='Stop';$inv=[Globalization.CultureInfo]::InvariantCulture
function Esc([object]$v){if($null-eq$v){return ''};([string]$v).Replace('\','\\').Replace("`n",'\n').Replace('"','\"')}
function Labels([hashtable]$h){if(-not$h.Count){return ''};'{'+(($h.Keys|Sort-Object|ForEach-Object{"$_=`"$(Esc $h[$_])`""})-join',')+'}'}
function Metric($lines,[string]$name,[double]$value,[hashtable]$labels=@{}){$lines.Add("$name$(Labels $labels) $($value.ToString('R',$inv))")}
function Key([string]$v){($v.ToLowerInvariant()-replace'[^a-z0-9]+','_').Trim('_')}

$lines=[Collections.Generic.List[string]]::new();$started=Get-Date;$errors=0
$sets=@(Get-Counter -ListSet * -ErrorAction SilentlyContinue|Where-Object{$_.CounterSetName -match '^(MSOLAP|MSAS\d*)' -and ($CounterGroup -contains (($_.CounterSetName -split ':')[-1]))})
$paths=@($sets|ForEach-Object{$_.PathsWithInstances+$_.Paths}|Sort-Object -Unique)
try{
  if($paths.Count){
    $samples=(Get-Counter -Counter $paths -SampleInterval $SampleIntervalSeconds -MaxSamples 1 -ErrorAction Stop).CounterSamples
    foreach($sample in $samples){
      $set=($sample.Path -split '\\')[-2];$counter=($sample.Path -split '\\')[-1];$counter=$counter -replace '\([^)]*\)$',''
      $group=($set -split ':')[-1];$perfInstance=if($sample.InstanceName){$sample.InstanceName}else{'_total'}
      $labels=@{counter_set=$set;group=$group;counter=$counter;perf_instance=$perfInstance}
      Metric $lines 'ssas_performance_counter_value' $sample.CookedValue $labels
      $map=@{
        'connection|current_connections'='ssas_performance_active_connections';'connection|requests_sec'='ssas_connection_requests_per_second';'connection|total_requests'='ssas_connection_requests_total';
        'connection|successes_sec'='ssas_connection_successes_per_second';'connection|total_successes'='ssas_connection_successes_total';'connection|failures_sec'='ssas_connection_failures_per_second';'connection|total_failures'='ssas_connection_failures_total';'connection|current_user_sessions'='ssas_performance_active_sessions';
        'cache|direct_hit_ratio'='ssas_cache_hit_ratio';'cache|current_kb'='ssas_cache_memory_kilobytes';
        'locks|current_locks'='ssas_current_locks';'locks|current_lock_waits'='ssas_current_lock_waits';'locks|lock_waits_sec'='ssas_lock_waits_per_second';'locks|total_deadlocks_detected'='ssas_deadlocks_total';
        'memory|memory_usage_kb'='ssas_memory_usage_kilobytes';'memory|memory_limit_low_kb'='ssas_memory_limit_low_kilobytes';'memory|memory_limit_high_kb'='ssas_memory_limit_high_kilobytes';'memory|memory_limit_hard_kb'='ssas_memory_limit_hard_kilobytes';'memory|quota_blocked'='ssas_memory_quota_blocked';'memory|filestore_page_faults_sec'='ssas_filestore_page_faults_per_second';
        'processing|rows_read_sec'='ssas_processing_rows_read_per_second';'processing|rows_written_sec'='ssas_processing_rows_written_per_second';'processing_aggregations|current_partitions'='ssas_processing_partitions';'processing_indexes|current_partitions'='ssas_processing_index_partitions';
        'storage_engine_query|queries_answered_sec'='ssas_query_rate';'storage_engine_query|avg_time_query'='ssas_query_duration_milliseconds';'storage_engine_query|total_queries'='ssas_storage_engine_queries_total';'storage_engine_query|total_query_failures'='ssas_query_failures_total';'storage_engine_query|current_measure_group_queries'='ssas_storage_engine_queries_active';'storage_engine_query|direct_queries_queries_sec'='ssas_directquery_rate';'storage_engine_query|total_direct_queries'='ssas_directquery_total';
        'reliability|current_panic_mode'='ssas_panic_mode';'reliability|total_memory_allocation_errors'='ssas_memory_allocation_errors_total';'reliability|total_user_errors'='ssas_user_errors_total';'reliability|total_system_errors'='ssas_system_errors_total';'reliability|number_of_threads_waiting_for_memory_due_to_high_memory_state'='ssas_memory_waiting_threads'
      }
      $lookup="$(Key $group)|$(Key $counter)";if($map.ContainsKey($lookup)){Metric $lines $map[$lookup] $sample.CookedValue @{counter_set=$set;perf_instance=$perfInstance}}
      if((Key $group)-eq'threads' -and (Key $counter)-match'^(.*)_(idle|busy)_.*threads$'){Metric $lines 'ssas_thread_pool_threads' $sample.CookedValue @{counter_set=$set;pool=$matches[1];state=$matches[2];perf_instance=$perfInstance}}
      if((Key $group)-eq'threads' -and (Key $counter)-match'^(.*)_job_queue_length$'){Metric $lines 'ssas_thread_pool_queue_length' $sample.CookedValue @{counter_set=$set;pool=$matches[1];perf_instance=$perfInstance}}
    }
  }else{$errors++}
}catch{$errors++}
Metric $lines 'ssas_performance_collector_errors' $errors
Metric $lines 'ssas_performance_collector_duration_seconds' ((Get-Date)-$started).TotalSeconds
Metric $lines 'ssas_performance_collector_last_run_timestamp_seconds' ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
$dir=Split-Path $OutputPath -Parent;New-Item $dir -ItemType Directory -Force|Out-Null;$tmp=Join-Path $dir ('.ssas-perf.'+[guid]::NewGuid().ToString('N')+'.tmp')
[IO.File]::WriteAllLines($tmp,$lines,[Text.UTF8Encoding]::new($false));Move-Item $tmp $OutputPath -Force
if($errors){Write-Warning 'No supported SSAS performance counter sets were sampled.'}
