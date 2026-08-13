#Requires -Version 5.1
<#
.SYNOPSIS
  Audits (and optionally hardens) required access for windows_exporter.
.DESCRIPTION
  Read-only by default. Checks local Administrator rights for install/upgrade,
  WinRM reachability (remote), install-folder and web-config ACLs, service
  account, TCP/9182 firewall/listen state, /metrics reachability, and
  textfile_inputs writability. With -Apply, tightens ACLs on the install root
  and web-config.yml for SYSTEM, Administrators, and the service account.
  Omit -ComputerName to inspect the local computer.
.EXAMPLE
  .\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
.EXAMPLE
  .\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.EXAMPLE
  .\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -Apply -PrometheusRemoteAddress 10.10.10.20
.EXAMPLE
  # Prefer Set-WindowsExporterRequiredAccess.ps1 to create ACLs/firewall/rights, then audit:
  .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
  .\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
.EXAMPLE
  .\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ComputerName SSAS01 -IncludeSsasChecks -Credential (Get-Credential)
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias('Computers')]
    [string[]]$ComputerName,

    [pscredential]$Credential,

    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',

    [string]$ServiceName = 'prometheus_windows_exporter',

    [ValidateRange(1,65535)]
    [int]$ListenPort = 9182,

    [string[]]$PrometheusRemoteAddress,

    [switch]$IncludeSsasChecks,

    [switch]$ShowRequirements,

    [switch]$Apply
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $targets = New-Object System.Collections.Generic.List[string]

    function Test-LocalComputerName([string]$Name) {
        $n = $Name.Trim()
        if (-not $n) { return $true }
        $localNames = @('.', 'localhost', '127.0.0.1', '::1', $env:COMPUTERNAME, [Environment]::MachineName)
        $n -in $localNames
    }

    function Show-RequirementsMatrix {
        $rows = @(
            [pscustomobject]@{ Role='Install/Upgrade operator'; Access='Local Administrators on target'; Why='Create/update service, copy files under Program Files, manage firewall' }
            [pscustomobject]@{ Role='Install/Upgrade client'; Access='WinRM / PowerShell Remoting to target'; Why='Install-WindowsExporterRemote.ps1 and Upgrade-WindowsExporterRemote.ps1' }
            [pscustomobject]@{ Role='windows_exporter service'; Access='Read install root + web-config.yml; write textfile_inputs when textfile is enabled'; Why='Start service, load config, publish custom SSAS .prom files' }
            [pscustomobject]@{ Role='windows_exporter service (default)'; Access='LocalSystem is enough for OS collectors'; Why='cpu/memory/disk/net/service/process/tcp baselines' }
            [pscustomobject]@{ Role='windows_exporter service (SQL)'; Access='Read SQL performance counters / instance registry'; Why='mssql collector' }
            [pscustomobject]@{ Role='windows_exporter service (Cluster)'; Access='Read cluster objects as LocalSystem or equivalent'; Why='mscluster collector' }
            [pscustomobject]@{ Role='prometheus_windows_ssas service'; Access='Connect to SSAS + read DMVs; Server Admin for full role/member counts'; Why='Install-SsasMetricsTask.ps1 / Collect-SsasMetrics.ps1' }
            [pscustomobject]@{ Role=('Prometheus scraper'); Access=("TCP/{0} to target; optional Basic Auth credentials" -f $ListenPort); Why='Scrape /metrics' }
            [pscustomobject]@{ Role='Config hardening'; Access='web-config.yml ACL limited to SYSTEM, Administrators, service account'; Why='Protect Basic Auth hashes / TLS material' }
        )
        foreach ($row in $rows) {
            Write-Host ""
            Write-Host ("[{0}]" -f $row.Role) -ForegroundColor Green
            Write-Host ("  Access : {0}" -f $row.Access)
            Write-Host ("  Why    : {0}" -f $row.Why)
        }
    }

    if ($ShowRequirements) {
        Write-Host "windows_exporter required access (port $ListenPort)" -ForegroundColor Cyan
        Show-RequirementsMatrix
    }

    $auditScript = {
        param(
            [string]$Root,
            [string]$Name,
            [int]$Port,
            [string[]]$RemoteAddresses,
            [bool]$DoApply,
            [bool]$SsasChecks,
            [bool]$WhatIfPreferred
        )

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Continue'
        $rows = New-Object System.Collections.Generic.List[object]

        function Add-Row([string]$Category,[string]$Check,[string]$Status,[string]$Detail,[string]$Required='') {
            $rows.Add([pscustomobject]@{
                ComputerName = $env:COMPUTERNAME
                Category     = $Category
                Check        = $Check
                Status       = $Status
                Detail       = $Detail
                Required     = $Required
            }) | Out-Null
        }

        function Test-IsAdministrator {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]$id
            $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        function Get-ServiceAccountName([string]$Service) {
            $escaped = $Service.Replace("'","''")
            $svc = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction SilentlyContinue
            if (-not $svc) { return $null }
            $svc.StartName
        }

        function Convert-AccountToNtAccount([string]$Account) {
            if (-not $Account) { return $null }
            switch -Regex ($Account) {
                '^(LocalSystem|\\\.\\LocalSystem)$' { return 'NT AUTHORITY\SYSTEM' }
                '^(NT AUTHORITY\\LocalService|LocalService)$' { return 'NT AUTHORITY\LOCAL SERVICE' }
                '^(NT AUTHORITY\\NetworkService|NetworkService)$' { return 'NT AUTHORITY\NETWORK SERVICE' }
                '^(?i)NT SERVICE\\(.+)$' { return ('NT SERVICE\' + $Matches[1]) }
                default { return $Account }
            }
        }

        function Test-AclAllows([string]$Path,[string]$Account,[string]$Need) {
            if (-not (Test-Path -LiteralPath $Path)) { return $false }
            $acl = Get-Acl -LiteralPath $Path
            $nt = Convert-AccountToNtAccount $Account
            if (-not $nt) { return $false }
            $rightsNeeded = switch ($Need) {
                'Read'  { [Security.AccessControl.FileSystemRights]::ReadAndExecute }
                'Write' { [Security.AccessControl.FileSystemRights]::Modify }
                'Full'  { [Security.AccessControl.FileSystemRights]::FullControl }
                default { [Security.AccessControl.FileSystemRights]::Read }
            }
            foreach ($rule in $acl.Access) {
                $id = $null
                try { $id = $rule.IdentityReference.Translate([Security.Principal.NTAccount]).Value } catch { $id = $rule.IdentityReference.Value }
                if ($rule.IdentityReference.Value -ieq $nt -or $id -ieq $nt) {
                    if (($rule.FileSystemRights -band $rightsNeeded) -eq $rightsNeeded -and $rule.AccessControlType -eq 'Allow') {
                        return $true
                    }
                }
            }
            # Administrators / SYSTEM often covered via BUILTIN groups; treat as OK when elevated SYSTEM path exists
            if ($nt -eq 'NT AUTHORITY\SYSTEM') {
                foreach ($rule in $acl.Access) {
                    if ($rule.IdentityReference.Value -match 'SYSTEM' -and $rule.AccessControlType -eq 'Allow') { return $true }
                }
            }
            return $false
        }

        function Set-HardenedAcl {
            param(
                [string]$Path,
                [string]$ServiceAccount,
                [bool]$AllowServiceWrite
            )
            if (-not (Test-Path -LiteralPath $Path)) { return }
            $acl = Get-Acl -LiteralPath $Path
            $acl.SetAccessRuleProtection($true, $false)
            foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
            $inheritance = if ((Get-Item -LiteralPath $Path) -is [IO.DirectoryInfo]) {
                [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
            } else {
                [Security.AccessControl.InheritanceFlags]::None
            }
            $propagation = [Security.AccessControl.PropagationFlags]::None
            $admins = New-Object Security.AccessControl.FileSystemAccessRule('BUILTIN\Administrators','FullControl',$inheritance,$propagation,'Allow')
            $system = New-Object Security.AccessControl.FileSystemAccessRule('NT AUTHORITY\SYSTEM','FullControl',$inheritance,$propagation,'Allow')
            [void]$acl.AddAccessRule($admins)
            [void]$acl.AddAccessRule($system)
            $svcNt = Convert-AccountToNtAccount $ServiceAccount
            if ($svcNt -and $svcNt -ne 'NT AUTHORITY\SYSTEM') {
                $right = if ($AllowServiceWrite) { 'Modify' } else { 'ReadAndExecute' }
                $svcRule = New-Object Security.AccessControl.FileSystemAccessRule($svcNt,$right,$inheritance,$propagation,'Allow')
                [void]$acl.AddAccessRule($svcRule)
            }
            Set-Acl -LiteralPath $Path -AclObject $acl
        }

        $isAdmin = Test-IsAdministrator
        Add-Row 'Operator' 'Local Administrators' $(if ($isAdmin) { 'OK' } else { 'FAIL' }) `
            $(if ($isAdmin) { 'Current session is elevated' } else { 'Current session is not elevated' }) `
            'Required for install/upgrade, service create, firewall, ACL hardening'

        $exe = Join-Path $Root 'bin\windows_exporter.exe'
        $web = Join-Path $Root 'config\web-config.yml'
        $profiles = Join-Path $Root 'profiles'
        $scriptsPs = Join-Path $Root 'scripts\powershell'
        $collectorDir = Join-Path $Root 'collector'
        $ssasConfig = Join-Path $collectorDir 'ssas-collector.json'
        $textDir = Join-Path $Root 'textfile_inputs'

        Add-Row 'Package' 'InstallRoot' $(if (Test-Path -LiteralPath $Root) { 'OK' } else { 'WARN' }) $Root 'Default deploy path'
        Add-Row 'Package' 'windows_exporter.exe' $(if (Test-Path -LiteralPath $exe) { 'OK' } else { 'WARN' }) $exe 'Required binary'
        Add-Row 'Package' 'web-config.yml' $(if (Test-Path -LiteralPath $web) { 'OK' } else { 'WARN' }) $web 'Loaded via --web.config.file'
        Add-Row 'Package' 'profiles/' $(if (Test-Path -LiteralPath $profiles) { 'OK' } else { 'WARN' }) $profiles 'Required for role-based install'
        Add-Row 'Package' 'scripts/powershell/' $(if (Test-Path -LiteralPath $scriptsPs) { 'OK' } else { 'WARN' }) $scriptsPs 'Required by remote install/upgrade'
        Add-Row 'Package' 'collector/' $(if (Test-Path -LiteralPath $collectorDir) { 'OK' } else { 'WARN' }) $collectorDir 'Runtime collector configuration directory'
        Add-Row 'Package' 'collector/ssas-collector.json' $(if (Test-Path -LiteralPath $ssasConfig) { 'OK' } else { 'INFO' }) $ssasConfig 'Created by Install-SsasMetricsTask.ps1 when SSAS collection is configured'
        Add-Row 'Package' 'textfile_inputs/' $(if (Test-Path -LiteralPath $textDir) { 'OK' } else { 'WARN' }) $textDir 'Created by install/upgrade; needed for SSAS textfile metrics'

        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        $startName = Get-ServiceAccountName $Name
        if ($svc) {
            Add-Row 'Service' 'windows_exporter service' 'OK' ("Status={0}; StartName={1}" -f $svc.Status, $startName) 'Service must exist and start as LocalSystem or least-privilege account'
        } else {
            Add-Row 'Service' 'windows_exporter service' 'WARN' 'Service not found' 'Create with Install-WindowsExporterRemote.ps1 or New-Service'
            $startName = 'LocalSystem'
        }
        $mainEventSourceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\$Name"
        Add-Row 'Service' 'Application event source' $(if (Test-Path -LiteralPath $mainEventSourceKey) { 'OK' } else { 'WARN' }) `
            $Name 'Install/upgrade events use the service name; NSSM internal events retain source nssm'

        $svcNt = Convert-AccountToNtAccount $startName
        if (Test-Path -LiteralPath $Root) {
            $canReadRoot = Test-AclAllows $Root $startName 'Read'
            Add-Row 'ACL' 'InstallRoot readable by service' $(if ($canReadRoot -or $svcNt -eq 'NT AUTHORITY\SYSTEM') { 'OK' } else { 'FAIL' }) `
                ("Account={0}" -f $startName) 'Service account needs ReadAndExecute on install root'
        }
        if (Test-Path -LiteralPath $web) {
            $canReadWeb = Test-AclAllows $web $startName 'Read'
            Add-Row 'ACL' 'web-config.yml readable by service' $(if ($canReadWeb -or $svcNt -eq 'NT AUTHORITY\SYSTEM') { 'OK' } else { 'FAIL' }) `
                ("Account={0}" -f $startName) 'Service account needs Read on web-config.yml'
        }
        if (Test-Path -LiteralPath $collectorDir) {
            $canReadCollector = Test-AclAllows $collectorDir $startName 'Read'
            Add-Row 'ACL' 'collector readable by service/task' $(if ($canReadCollector -or $svcNt -eq 'NT AUTHORITY\SYSTEM') { 'OK' } else { 'WARN' }) `
                ("Account={0}" -f $startName) 'Required for runtime collector configuration'
        }
        if (Test-Path -LiteralPath $textDir) {
            $canWriteText = Test-AclAllows $textDir $startName 'Write'
            Add-Row 'ACL' 'textfile_inputs writable by service/task' $(if ($canWriteText -or $svcNt -eq 'NT AUTHORITY\SYSTEM') { 'OK' } else { 'WARN' }) `
                ("Account={0}" -f $startName) 'Required when textfile collector / SSAS task writes .prom files'
        }

        $fw = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
            $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow'
        } | ForEach-Object {
            $ports = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_ -ErrorAction SilentlyContinue
            if ($ports -and [string]$ports.LocalPort -match "(^|,)$Port(,|$)") { $_ }
        }
        if ($fw) {
            Add-Row 'Network' ("Firewall TCP/{0}" -f $Port) 'OK' (($fw | Select-Object -ExpandProperty DisplayName) -join '; ') ("Prometheus must reach TCP/{0}" -f $Port)
        } else {
            Add-Row 'Network' ("Firewall TCP/{0}" -f $Port) 'WARN' 'No enabled inbound Allow rule matched' ("Restrict RemoteAddress to Prometheus IPs on TCP/{0}" -f $Port)
        }

        $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        Add-Row 'Network' ("Listen TCP/{0}" -f $Port) $(if ($listening) { 'OK' } else { 'WARN' }) `
            $(if ($listening) { ($listening | Select-Object -ExpandProperty OwningProcess) -join ',' } else { 'Nothing listening' }) `
            'windows_exporter web.listen-address'

        try {
            $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:{0}/metrics" -f $Port) -UseBasicParsing -TimeoutSec 5
            Add-Row 'Network' '/metrics local scrape' 'OK' ("HTTP {0}" -f [int]$resp.StatusCode) 'Anonymous scrape OK when Basic Auth is disabled'
        } catch {
            $code = $null
            try { $code = [int]$_.Exception.Response.StatusCode } catch {}
            if ($code -eq 401) {
                Add-Row 'Network' '/metrics local scrape' 'OK' 'HTTP 401 (Basic Auth enabled)' 'Prometheus needs matching basic_auth credentials'
            } else {
                Add-Row 'Network' '/metrics local scrape' 'WARN' $_.Exception.Message 'Service should answer on /metrics'
            }
        }

        $hasSql = [bool]@(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(MSSQLSERVER|MSSQL\$.+)$' })
        $hasSsas = [bool]@(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(MSSQLServerOLAPService|MSOLAP\$.+)$' })
        if ($hasSql) {
            Add-Row 'Role' 'SQL Server detected' 'INFO' 'mssql collector needs performance-counter access' 'Service account must read SQL PDH counters'
        }
        if ($hasSsas -or $SsasChecks) {
            $ssasService = Get-Service -Name 'prometheus_windows_ssas' -ErrorAction SilentlyContinue
            Add-Row 'SSAS' 'prometheus_windows_ssas service' $(if ($ssasService -and $ssasService.Status -eq 'Running') { 'OK' } else { 'WARN' }) `
                $(if ($ssasService) { $ssasService.Status.ToString() } else { 'Not installed' }) 'Install with Install-SsasMetricsTask.ps1; needs SSAS connect + DMV rights'
            $eventSourceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\prometheus_windows_ssas'
            Add-Row 'SSAS' 'Application event source' $(if (Test-Path -LiteralPath $eventSourceKey) { 'OK' } else { 'WARN' }) `
                'prometheus_windows_ssas' 'Collector lifecycle and errors should appear under this source in Event Viewer > Application'
            $adomd = [bool]([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match 'AnalysisServices' })
            if (-not $adomd) {
                try {
                    $null = [Reflection.Assembly]::LoadWithPartialName('Microsoft.AnalysisServices.AdomdClient')
                    $adomd = $true
                } catch { $adomd = $false }
            }
            Add-Row 'SSAS' 'ADOMD/AMO libraries' $(if ($adomd) { 'OK' } else { 'WARN' }) `
                $(if ($adomd) { 'Loadable' } else { 'Not loaded in this session; confirm SSAS client libs on host' }) `
                'Required by Collect-SsasMetrics.ps1'
        }

        if ($DoApply) {
            if (-not $isAdmin) {
                Add-Row 'Apply' 'ACL/firewall hardening' 'FAIL' 'Administrator rights required for -Apply' 'Re-run elevated'
            } else {
                if (-not $WhatIfPreferred) {
                    if (-not (Test-Path -LiteralPath $textDir)) {
                        New-Item -Path $textDir -ItemType Directory -Force | Out-Null
                    }
                    if (Test-Path -LiteralPath $Root) {
                        Set-HardenedAcl -Path $Root -ServiceAccount $startName -AllowServiceWrite:$false
                        Set-HardenedAcl -Path $textDir -ServiceAccount $startName -AllowServiceWrite:$true
                    }
                    if (Test-Path -LiteralPath $web) {
                        Set-HardenedAcl -Path $web -ServiceAccount $startName -AllowServiceWrite:$false
                    }
                    Add-Row 'Apply' 'ACL hardening' 'OK' 'SYSTEM + Administrators (+ service account when not LocalSystem)' 'Least privilege on package files'

                    if ($RemoteAddresses -and $RemoteAddresses.Count -gt 0) {
                        $ruleName = "Prometheus windows_exporter $Port"
                        $existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                        if ($existing) { $existing | Remove-NetFirewallRule -ErrorAction SilentlyContinue }
                        New-NetFirewallRule -DisplayName $ruleName `
                            -Direction Inbound -Protocol TCP -LocalPort $Port `
                            -RemoteAddress $RemoteAddresses -Action Allow | Out-Null
                        Add-Row 'Apply' 'Firewall rule' 'OK' ("{0} <= {1}" -f $ruleName, ($RemoteAddresses -join ',')) ("Allow only Prometheus hosts on TCP/{0}" -f $Port)
                    } else {
                        Add-Row 'Apply' 'Firewall rule' 'SKIP' 'Pass -PrometheusRemoteAddress to create a scoped rule' ("TCP/{0}" -f $Port)
                    }
                } else {
                    Add-Row 'Apply' 'ACL/firewall hardening' 'WhatIf' 'No changes applied' 'Re-run without -WhatIf'
                }
            }
        }

        $rows
    }

    function Invoke-AccessAudit {
        param(
            [string]$Computer,
            [pscredential]$Credential
        )

        $args = @($InstallRoot, $ServiceName, $ListenPort, $PrometheusRemoteAddress, [bool]$Apply, [bool]$IncludeSsasChecks, [bool]$WhatIfPreference)
        if (Test-LocalComputerName $Computer) {
            & $auditScript @args
            return
        }

        $sessionArgs = @{ ComputerName = $Computer; ErrorAction = 'Stop' }
        if ($Credential) { $sessionArgs.Credential = $Credential }
        try {
            Test-WSMan -ComputerName $Computer -ErrorAction Stop | Out-Null
        } catch {
            return @(
                [pscustomobject]@{
                    ComputerName = $Computer
                    Category     = 'WinRM'
                    Check        = 'PowerShell Remoting'
                    Status       = 'FAIL'
                    Detail       = $_.Exception.Message
                    Required     = 'Enable WinRM and allow Administrator remoting'
                }
            )
        }
        Invoke-Command @sessionArgs -ScriptBlock $auditScript -ArgumentList $args
    }
}

process {
    if ($ShowRequirements -and -not $ComputerName -and -not $Apply) { return }
    if ($ComputerName) {
        foreach ($c in $ComputerName) {
            if ($c) { [void]$targets.Add($c.Trim()) }
        }
    }
}

end {
    if ($ShowRequirements -and $targets.Count -eq 0 -and -not $Apply) { return }
    if ($targets.Count -eq 0) { [void]$targets.Add($env:COMPUTERNAME) }

    $all = @()
    foreach ($computer in ($targets | Select-Object -Unique)) {
        Write-Host "`n===== $computer =====" -ForegroundColor Yellow
        try {
            if ($Apply -and -not $PSCmdlet.ShouldProcess($computer, 'Audit and harden windows_exporter access')) {
                continue
            }
            $rows = @(Invoke-AccessAudit -Computer $computer -Credential $Credential)
            $all += $rows
            $rows | Select-Object ComputerName, Category, Check, Status, Detail | Format-Table -AutoSize -Wrap
        } catch {
            $err = [pscustomobject]@{
                ComputerName = $computer
                Category     = 'Error'
                Check        = 'Audit'
                Status       = 'FAIL'
                Detail       = $_.Exception.Message
                Required     = ''
            }
            $all += $err
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($all.Count) {
        $summary = $all | Group-Object Status | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }
        Write-Host ("`nSummary: " + ($summary -join ', ')) -ForegroundColor Cyan
        $failed = @($all | Where-Object Status -eq 'FAIL')
        if ($failed.Count) { exit 1 }
    }
}
