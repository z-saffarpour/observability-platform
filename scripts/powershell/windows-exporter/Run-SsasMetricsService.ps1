#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ServiceName = 'prometheus_windows_ssas',
    [Parameter(Mandatory)][string]$CollectorScript,
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateRange(1, 60)][int]$IntervalMinutes = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($requiredFile in @($CollectorScript, $ConfigPath)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required SSAS service file was not found: $requiredFile"
    }
}

if (-not ('PrometheusWindowsSsas.ServiceHost' -as [type])) {
    Add-Type -ReferencedAssemblies 'System.ServiceProcess' -TypeDefinition @'
using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.Threading;

namespace PrometheusWindowsSsas
{
    public sealed class ServiceHost : ServiceBase
    {
        private readonly string powershellPath;
        private readonly string arguments;
        private readonly int intervalMilliseconds;
        private Timer timer;
        private Process child;
        private int collecting;

        public ServiceHost(string serviceName, string powershellPath, string arguments, int intervalMinutes)
        {
            ServiceName = serviceName;
            CanStop = true;
            CanShutdown = true;
            AutoLog = true;
            this.powershellPath = powershellPath;
            this.arguments = arguments;
            intervalMilliseconds = checked(intervalMinutes * 60 * 1000);
        }

        protected override void OnStart(string[] args)
        {
            timer = new Timer(Collect, null, 0, intervalMilliseconds);
        }

        private void Collect(object state)
        {
            if (Interlocked.Exchange(ref collecting, 1) != 0) return;
            try
            {
                var startInfo = new ProcessStartInfo
                {
                    FileName = powershellPath,
                    Arguments = arguments,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WorkingDirectory = AppDomain.CurrentDomain.BaseDirectory
                };
                child = Process.Start(startInfo);
                child.WaitForExit();
                if (child.ExitCode != 0)
                    EventLog.WriteEntry("SSAS collector exited with code " + child.ExitCode, EventLogEntryType.Error);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry(ex.ToString(), EventLogEntryType.Error);
            }
            finally
            {
                if (child != null) { child.Dispose(); child = null; }
                Interlocked.Exchange(ref collecting, 0);
            }
        }

        protected override void OnStop()
        {
            if (timer != null) { timer.Dispose(); timer = null; }
            var running = child;
            if (running != null && !running.HasExited)
            {
                try { running.Kill(); } catch { }
            }
        }

        protected override void OnShutdown() { OnStop(); }

        public static void RunService(ServiceHost service)
        {
            ServiceBase.Run(service);
        }
    }
}
'@
}

function Quote-ServiceArgument {
    param([string]$Value)
    '"{0}"' -f $Value.Replace('"', '\"')
}

$collectorArguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File {0} -ConfigPath {1}' -f `
    (Quote-ServiceArgument $CollectorScript), (Quote-ServiceArgument $ConfigPath)
$serviceHostInstance = [PrometheusWindowsSsas.ServiceHost]::new(
    $ServiceName,
    (Join-Path $PSHOME 'powershell.exe'),
    $collectorArguments,
    $IntervalMinutes
)
[PrometheusWindowsSsas.ServiceHost]::RunService($serviceHostInstance)
