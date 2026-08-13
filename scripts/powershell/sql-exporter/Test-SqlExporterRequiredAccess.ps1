#Requires -Version 5.1
<#
.SYNOPSIS
  Audits required access for sql_exporter (and optionally hardens ACLs).
.DESCRIPTION
  Read-only by default. Checks local Administrator rights, WinRM reachability
  (when -ComputerName is set), install-folder and web-config ACLs, service
  account, TCP/9399 firewall/listen state, and /metrics. With -Apply, tightens
  ACLs on the install root and web-config.yml for SYSTEM, Administrators, and
  the service account. Use -ShowRequirements for the access matrix.
  SQL login grants are NOT applied here — use scripts/sql/Create-SqlExporterLogin.sql.
.EXAMPLE
  .\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 -ShowRequirements
.EXAMPLE
  .\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1
.EXAMPLE
  .\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
.EXAMPLE
  .\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
  .\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias('Computers')]
    [string[]]$ComputerName,

    [pscredential]$Credential,

    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\sql-exporter',

    [string]$ServiceName = 'prometheus_sql_exporter',

    [ValidateRange(1,65535)]
    [int]$ListenPort = 9399,

    [string[]]$PrometheusRemoteAddress,

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
            [pscustomobject]@{ Role = 'Install/Upgrade operator'; Access = 'Local Administrators on target'; Why = 'Create/update service, copy files under Program Files, manage firewall/ACL' }
            [pscustomobject]@{ Role = 'Install/Upgrade client'; Access = 'WinRM / PowerShell Remoting to target'; Why = 'Install-SqlExporterRemote.ps1, Upgrade-SqlExporterRemote.ps1, Deploy-*' }
            [pscustomobject]@{ Role = 'sql_exporter Windows service'; Access = 'Read install root + web-config.yml; Log on as a service (custom accounts)'; Why = 'Start service and load config' }
            [pscustomobject]@{ Role = 'sql_exporter to SQL Server'; Access = 'VIEW SERVER STATE + VIEW ANY DEFINITION (plus optional msdb/SSISDB/user DBs)'; Why = 'Collector queries; use Create-SqlExporterLogin.sql' }
            [pscustomobject]@{ Role = 'Prometheus scraper'; Access = ("TCP/{0} to target; optional Basic Auth credentials" -f $ListenPort); Why = 'Scrape /metrics' }
            [pscustomobject]@{ Role = 'Config hardening'; Access = 'web-config.yml ACL limited to SYSTEM, Administrators, service account'; Why = 'Protect Basic Auth hashes / TLS material' }
        )
        Write-Host "sql_exporter required access (port $ListenPort)" -ForegroundColor Cyan
        foreach ($row in $rows) {
            Write-Host ""
            Write-Host ("[{0}]" -f $row.Role) -ForegroundColor Green
            Write-Host ("  Access : {0}" -f $row.Access)
            Write-Host ("  Why    : {0}" -f $row.Why)
        }
        Write-Host ""
        Write-Host 'SQL grants: scripts/sql/Create-SqlExporterLogin.sql (not applied by Set/Test PowerShell scripts).' -ForegroundColor DarkGray
    }

    if ($ShowRequirements) {
        Show-RequirementsMatrix
    }

    $auditScript = {
        param(
            [string]$Root,
            [string]$Name,
            [int]$Port,
            [bool]$DoApply,
            [bool]$WhatIfPreferred
        )

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Continue'
        $rows = New-Object System.Collections.Generic.List[object]

        function Add-Row([string]$Category, [string]$Check, [string]$Status, [string]$Detail, [string]$Required = '') {
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
            ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        function Get-ServiceAccountName([string]$Service) {
            $escaped = $Service.Replace("'", "''")
            $svc = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction SilentlyContinue
            if ($svc) { return $svc.StartName }
            $null
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

        function Test-AclAllows([string]$Path, [string]$Account, [string]$Need) {
            if (-not (Test-Path -LiteralPath $Path)) { return $false }
            $acl = Get-Acl -LiteralPath $Path
            $nt = Convert-AccountToNtAccount $Account
            if (-not $nt) { return $false }
            $rightsNeeded = switch ($Need) {
                'Read' { [Security.AccessControl.FileSystemRights]::ReadAndExecute }
                default { [Security.AccessControl.FileSystemRights]::Read }
            }
            foreach ($rule in $acl.Access) {
                $id = $null
                try { $id = $rule.IdentityReference.Translate([Security.Principal.NTAccount]).Value } catch { $id = $rule.IdentityReference.Value }
                if (($rule.IdentityReference.Value -ieq $nt -or $id -ieq $nt) -and
                    (($rule.FileSystemRights -band $rightsNeeded) -eq $rightsNeeded) -and
                    $rule.AccessControlType -eq 'Allow') {
                    return $true
                }
            }
            if ($nt -eq 'NT AUTHORITY\SYSTEM') {
                foreach ($rule in $acl.Access) {
                    if ($rule.IdentityReference.Value -match 'SYSTEM' -and $rule.AccessControlType -eq 'Allow') { return $true }
                }
            }
            return $false
        }

        function Set-HardenedAcl {
            param([string]$Path, [string]$ServiceAccount)
            if (-not (Test-Path -LiteralPath $Path)) { return }
            $item = Get-Item -LiteralPath $Path
            $acl = Get-Acl -LiteralPath $Path
            $acl.SetAccessRuleProtection($true, $false)
            foreach ($rule in @($acl.Access)) { [void]$acl.RemoveAccessRule($rule) }
            $inheritance = if ($item -is [IO.DirectoryInfo]) {
                [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
            } else {
                [Security.AccessControl.InheritanceFlags]::None
            }
            $propagation = [Security.AccessControl.PropagationFlags]::None
            [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('BUILTIN\Administrators', 'FullControl', $inheritance, $propagation, 'Allow')))
            [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('NT AUTHORITY\SYSTEM', 'FullControl', $inheritance, $propagation, 'Allow')))
            $svcNt = Convert-AccountToNtAccount $ServiceAccount
            if ($svcNt -and $svcNt -ne 'NT AUTHORITY\SYSTEM') {
                [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($svcNt, 'ReadAndExecute', $inheritance, $propagation, 'Allow')))
            }
            Set-Acl -LiteralPath $Path -AclObject $acl
        }

        $isAdmin = Test-IsAdministrator
        Add-Row 'Operator' 'Local Administrators' $(if ($isAdmin) { 'OK' } else { 'FAIL' }) `
            $(if ($isAdmin) { 'Current session is elevated' } else { 'Current session is not elevated' }) `
            'Required for install/upgrade, service create, firewall, ACL hardening'

        $exe = Join-Path $Root 'bin\sql_exporter.exe'
        $cfg = Join-Path $Root 'config\sql_exporter.yml'
        $web = Join-Path $Root 'config\web-config.yml'
        $collector = Join-Path $Root 'collectors'
        $profiles = Join-Path $Root 'profiles'

        Add-Row 'Package' 'InstallRoot' $(if (Test-Path -LiteralPath $Root) { 'OK' } else { 'WARN' }) $Root 'Default deploy path'
        Add-Row 'Package' 'sql_exporter.exe' $(if (Test-Path -LiteralPath $exe) { 'OK' } else { 'WARN' }) $exe 'Required binary'
        Add-Row 'Package' 'sql_exporter.yml' $(if (Test-Path -LiteralPath $cfg) { 'OK' } else { 'WARN' }) $cfg 'DSN + collectors'
        Add-Row 'Package' 'web-config.yml' $(if (Test-Path -LiteralPath $web) { 'OK' } else { 'WARN' }) $web 'TLS / Basic Auth'
        Add-Row 'Package' 'collectors/' $(if (Test-Path -LiteralPath $collector) { 'OK' } else { 'WARN' }) $collector 'Collector definitions'
        Add-Row 'Package' 'profiles/' $(if (Test-Path -LiteralPath $profiles) { 'OK' } else { 'WARN' }) $profiles 'Role profiles'

        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        $startName = Get-ServiceAccountName $Name
        if ($svc) {
            Add-Row 'Service' $Name 'OK' ("Status={0}; StartName={1}" -f $svc.Status, $startName) 'Service must exist and run under an account that can reach SQL'
        } else {
            Add-Row 'Service' $Name 'WARN' 'Service not found' 'Create with Install-SqlExporterRemote.ps1'
            $startName = 'LocalSystem'
        }
        $eventSourceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\$Name"
        Add-Row 'Service' 'Application event source' $(if (Test-Path -LiteralPath $eventSourceKey) { 'OK' } else { 'WARN' }) `
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

        $fw = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
            $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow'
        } | ForEach-Object {
            $ports = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_ -ErrorAction SilentlyContinue
            if ($ports -and [string]$ports.LocalPort -match ('(^|,)' + $Port + '(,|$)')) { $_ }
        }
        if ($fw) {
            Add-Row 'Network' ("Firewall TCP/{0}" -f $Port) 'OK' (($fw | Select-Object -ExpandProperty DisplayName) -join '; ') ("Prometheus must reach TCP/{0}" -f $Port)
        } else {
            Add-Row 'Network' ("Firewall TCP/{0}" -f $Port) 'WARN' 'No enabled inbound Allow rule matched' ("Restrict RemoteAddress to Prometheus IPs on TCP/{0}" -f $Port)
        }

        $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        Add-Row 'Network' ("Listen TCP/{0}" -f $Port) $(if ($listening) { 'OK' } else { 'WARN' }) `
            $(if ($listening) { ($listening | Select-Object -ExpandProperty OwningProcess) -join ',' } else { 'Nothing listening' }) `
            'sql_exporter --web.listen-address'

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

        Add-Row 'SQL' 'Login grants' 'INFO' 'Not audited by this script' 'Run Create-SqlExporterLogin.sql as sysadmin for VIEW SERVER STATE / VIEW ANY DEFINITION / optional msdb|SSISDB|user DB grants'

        if ($DoApply) {
            if (-not $isAdmin) {
                Add-Row 'Apply' 'ACL hardening' 'FAIL' 'Administrator rights required for -Apply' 'Re-run elevated'
            } elseif (-not $WhatIfPreferred) {
                if (Test-Path -LiteralPath $Root) {
                    Set-HardenedAcl -Path $Root -ServiceAccount $startName
                    Add-Row 'Apply' 'ACL InstallRoot' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute'
                }
                if (Test-Path -LiteralPath $web) {
                    Set-HardenedAcl -Path $web -ServiceAccount $startName
                    Add-Row 'Apply' 'ACL web-config.yml' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute'
                }
            } else {
                Add-Row 'Apply' 'ACL hardening' 'WhatIf' 'Would harden install root and web-config.yml' ''
            }
        }

        $rows
    }
}

process {
    if ($ComputerName) {
        foreach ($c in $ComputerName) {
            if ($c) { [void]$targets.Add($c.Trim()) }
        }
    }
}

end {
    if (-not $ShowRequirements -and $targets.Count -eq 0) {
        [void]$targets.Add($env:COMPUTERNAME)
    }
    if ($targets.Count -eq 0) { return }

    $all = @()
    foreach ($computer in ($targets | Select-Object -Unique)) {
        Write-Host "`n===== $computer =====" -ForegroundColor Yellow
        try {
            if (-not $PSCmdlet.ShouldProcess($computer, 'Audit sql_exporter required access')) { continue }

            if (Test-LocalComputerName $computer) {
                $result = & $auditScript $InstallRoot $ServiceName $ListenPort ([bool]$Apply) ([bool]$WhatIfPreference)
            } else {
                $sessionParams = @{ ComputerName = $computer; ErrorAction = 'Stop' }
                if ($Credential) { $sessionParams.Credential = $Credential }
                $session = New-PSSession @sessionParams
                try {
                    $result = Invoke-Command -Session $session -ScriptBlock $auditScript -ArgumentList `
                        $InstallRoot, $ServiceName, $ListenPort, ([bool]$Apply), ([bool]$WhatIfPreference)
                } finally {
                    Remove-PSSession $session -ErrorAction SilentlyContinue
                }
            }
            $all += $result
            $result | Format-Table Category, Check, Status, Detail -AutoSize | Out-String | Write-Host
        } catch {
            Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
            $all += [pscustomobject]@{
                ComputerName = $computer
                Category     = 'Session'
                Check        = 'Connect'
                Status       = 'FAIL'
                Detail       = $_.Exception.Message
                Required     = 'WinRM / PowerShell Remoting'
            }
        }
    }

    $failed = @($all | Where-Object Status -eq 'FAIL')
    if ($failed.Count -gt 0) { exit 1 }
    exit 0
}
