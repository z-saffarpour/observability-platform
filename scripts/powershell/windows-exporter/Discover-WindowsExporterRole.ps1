#Requires -Version 5.1
<#
.SYNOPSIS
  Detects Windows / SQL / SSAS / PBIRS / Dynamics / Cluster / RDS roles.
.DESCRIPTION
  Read-only. Omit -ComputerName to inspect the local computer. From a client,
  pass remote servers; the script uses WinRM and does not change the target.
.PARAMETER ComputerName
  Target servers. Localhost aliases run locally without WinRM.
.PARAMETER Credential
  Optional WinRM credential for remote targets.
.EXAMPLE
  .\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.EXAMPLE
  .\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
.EXAMPLE
  Get-Content .\servers.txt | .\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias('Computers')]
    [string[]]$ComputerName,

    [pscredential]$Credential
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $targets = New-Object System.Collections.Generic.List[string]

    $discoverRole = {
        $services = @(Get-Service -ErrorAction SilentlyContinue)
        $serviceNames = @($services.Name)

        $hasSql = [bool]($serviceNames -match '^(MSSQLSERVER|MSSQL\$.+)$')
        $hasSsas = [bool]($serviceNames -match '^(MSSQLServerOLAPService|MSOLAP\$.+)$')
        $hasPbirs = [bool]($serviceNames -match '^(PowerBIReportServer|PBIRS.*|SQLServerReportingServices|ReportServer.*)$')
        $hasCluster = [bool]($serviceNames -contains 'ClusSvc')
        $hasAx2012 = [bool]($serviceNames -match '^AOS60\$.+$')
        $hasServiceFabric = [bool]($serviceNames -contains 'FabricHostSvc')
        $windowsFeatureCommand = Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue
        $hasTerminalServer = if ($windowsFeatureCommand) {
            [bool](Get-WindowsFeature -Name RDS-RD-Server -ErrorAction SilentlyContinue | Where-Object Installed)
        } else {
            $false
        }

        $profile = if ($hasAx2012 -and $hasServiceFabric) {
            'dynamics-platform.yml'
        } elseif ($hasAx2012) {
            'dynamics-ax-2012.yml'
        } elseif ($hasServiceFabric) {
            'd365-finance-operations.yml'
        } elseif ($hasCluster -and ($hasSql -or $hasSsas -or $hasPbirs)) {
            'data-platform-cluster.yml'
        } elseif ($hasCluster) {
            'windows-cluster.yml'
        } elseif (($hasSql -and $hasSsas) -or ($hasSql -and $hasPbirs) -or ($hasSsas -and $hasPbirs)) {
            'data-platform.yml'
        } elseif ($hasSql) {
            'sql-server.yml'
        } elseif ($hasSsas) {
            'ssas.yml'
        } elseif ($hasPbirs) {
            'powerbi-report-server.yml'
        } elseif ($hasTerminalServer) {
            'terminal-server.yml'
        } else {
            'windows-base.yml'
        }

        [pscustomobject]@{
            ComputerName          = $env:COMPUTERNAME
            SQLServer             = $hasSql
            SSAS                  = $hasSsas
            PowerBIReportServer   = $hasPbirs
            WindowsCluster        = $hasCluster
            DynamicsAX2012        = $hasAx2012
            ServiceFabric         = $hasServiceFabric
            TerminalServer        = $hasTerminalServer
            RecommendedProfile    = $profile
        }
    }

    function Test-LocalComputerName([string]$Name) {
        $n = $Name.Trim()
        if (-not $n) { return $true }
        $localNames = @('.', 'localhost', '127.0.0.1', '::1', $env:COMPUTERNAME, [Environment]::MachineName)
        $n -in $localNames
    }

    function Invoke-RoleDiscovery {
        param(
            [string]$Computer,
            [pscredential]$Credential
        )

        if (Test-LocalComputerName $Computer) {
            return & $discoverRole
        }

        $invokeArgs = @{
            ComputerName = $Computer
            ScriptBlock  = $discoverRole
            ErrorAction  = 'Stop'
        }
        if ($Credential) { $invokeArgs.Credential = $Credential }
        Invoke-Command @invokeArgs |
            Select-Object ComputerName, SQLServer, SSAS, PowerBIReportServer, WindowsCluster, DynamicsAX2012, ServiceFabric, TerminalServer, RecommendedProfile
    }
}

process {
    foreach ($name in @($ComputerName)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        [void]$targets.Add($name.Trim())
    }
}

end {
    if ($Credential -and $targets.Count -eq 0) {
        throw '-Credential requires -ComputerName.'
    }

    $unique = @($targets | Select-Object -Unique)
    if ($unique.Count -eq 0) {
        & $discoverRole
        return
    }

    foreach ($computer in $unique) {
        try {
            Invoke-RoleDiscovery -Computer $computer -Credential $Credential
        } catch {
            Write-Error "Failed to discover role on ${computer}: $($_.Exception.Message)"
        }
    }
}
