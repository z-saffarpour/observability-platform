#Requires -Version 5.1
<#
.SYNOPSIS
  Creates the required local access for windows_exporter (ACL, firewall, rights).
.DESCRIPTION
  Applies least-privilege ACLs on the install root, web-config.yml, and
  textfile_inputs; creates a scoped inbound firewall rule for the scrape port;
  optionally grants "Log on as a service" and membership in Performance Monitor
  Users for a custom service account. The target host must allow an elevated
  remoting session (or run locally as Administrator). Use
  Test-WindowsExporterRequiredAccess.ps1 to audit afterward.
.EXAMPLE
  .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
    -PrometheusRemoteAddress 10.10.10.20 -WhatIf
.EXAMPLE
  .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
    -PrometheusRemoteAddress 10.10.10.20,10.10.10.21
.EXAMPLE
  .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
    -ComputerName SQL01,SQL02 `
    -Credential (Get-Credential) `
    -ServiceAccount 'DOMAIN\svc-winexporter$' `
    -PrometheusRemoteAddress 10.10.10.20 `
    -GrantPerformanceMonitorUsers
.EXAMPLE
  .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
    -ComputerName SSAS01 `
    -Credential (Get-Credential) `
    -PrometheusRemoteAddress 10.10.10.20 `
    -SkipFirewall
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias('Computers')]
    [string[]]$ComputerName,

    [pscredential]$Credential,

    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter',

    [string]$ServiceName = 'prometheus_windows_exporter',

    [string]$ServiceAccount,

    [ValidateRange(1,65535)]
    [int]$ListenPort = 9182,

    [string[]]$PrometheusRemoteAddress,

    [switch]$GrantLogonAsService,

    [switch]$GrantPerformanceMonitorUsers,

    [switch]$SkipFirewall,

    [switch]$SkipAcl
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $targets = New-Object System.Collections.Generic.List[string]

    if (-not $SkipFirewall -and (-not $PrometheusRemoteAddress -or $PrometheusRemoteAddress.Count -eq 0)) {
        throw 'Specify -PrometheusRemoteAddress (Prometheus host IPs/CIDRs) or pass -SkipFirewall.'
    }

    function Test-LocalComputerName([string]$Name) {
        $n = $Name.Trim()
        if (-not $n) { return $true }
        $localNames = @('.', 'localhost', '127.0.0.1', '::1', $env:COMPUTERNAME, [Environment]::MachineName)
        $n -in $localNames
    }

    $grantScript = {
        param(
            [string]$Root,
            [string]$Name,
            [string]$AccountOverride,
            [int]$Port,
            [string[]]$RemoteAddresses,
            [bool]$DoLogonRight,
            [bool]$DoPerfMon,
            [bool]$NoFirewall,
            [bool]$NoAcl,
            [bool]$WhatIfPreferred
        )

        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
        $rows = New-Object System.Collections.Generic.List[object]

        function Test-IsAdministrator {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        function Add-Row([string]$Action,[string]$Status,[string]$Detail) {
            $rows.Add([pscustomobject]@{
                ComputerName = $env:COMPUTERNAME
                Action       = $Action
                Status       = $Status
                Detail       = $Detail
            }) | Out-Null
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

        function Test-BuiltinServiceAccount([string]$Account) {
            $nt = Convert-AccountToNtAccount $Account
            $nt -in @(
                'NT AUTHORITY\SYSTEM',
                'NT AUTHORITY\LOCAL SERVICE',
                'NT AUTHORITY\NETWORK SERVICE'
            )
        }

        function Test-VirtualServiceAccount([string]$Account) {
            $nt = Convert-AccountToNtAccount $Account
            [bool]($nt -match '(?i)^NT SERVICE\\')
        }

        function Get-ServiceAccountName([string]$Service) {
            $escaped = $Service.Replace("'","''")
            $svc = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction SilentlyContinue
            if ($svc) { return $svc.StartName }
            $null
        }

        function Set-HardenedAcl {
            param(
                [string]$Path,
                [string]$ServiceAccount,
                [bool]$AllowServiceWrite
            )
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
            [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('BUILTIN\Administrators','FullControl',$inheritance,$propagation,'Allow')))
            [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('NT AUTHORITY\SYSTEM','FullControl',$inheritance,$propagation,'Allow')))
            $svcNt = Convert-AccountToNtAccount $ServiceAccount
            if ($svcNt -and $svcNt -ne 'NT AUTHORITY\SYSTEM') {
                $right = if ($AllowServiceWrite) { 'Modify' } else { 'ReadAndExecute' }
                [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($svcNt,$right,$inheritance,$propagation,'Allow')))
            }
            Set-Acl -LiteralPath $Path -AclObject $acl
        }

        function Grant-UserRight {
            param([string]$Account,[string]$Right)
            if (Test-BuiltinServiceAccount $Account) { return 'SKIP' }
            if (Test-VirtualServiceAccount $Account) { return 'SKIP' }
            $nt = Convert-AccountToNtAccount $Account
            $sid = ([System.Security.Principal.NTAccount]$nt).Translate([System.Security.Principal.SecurityIdentifier]).Value
            $tempDir = Join-Path $env:TEMP ('winexp-rights-' + [guid]::NewGuid().ToString('N'))
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            try {
                $infExport = Join-Path $tempDir 'export.inf'
                $infImport = Join-Path $tempDir 'import.inf'
                $db = Join-Path $tempDir 'secedit.sdb'
                $log = Join-Path $tempDir 'secedit.log'
                $null = & secedit.exe /export /cfg $infExport /areas USER_RIGHTS 2>&1
                if (-not (Test-Path -LiteralPath $infExport)) { throw 'secedit export failed.' }
                $lines = Get-Content -LiteralPath $infExport
                $out = New-Object System.Collections.Generic.List[string]
                $found = $false
                foreach ($line in $lines) {
                    if ($line -match ("^\s*{0}\s*=" -f [regex]::Escape($Right))) {
                        $found = $true
                        if ($line -match [regex]::Escape($sid) -or $line -match [regex]::Escape($nt)) {
                            $out.Add($line)
                        } else {
                            $out.Add(($line.TrimEnd() + ",*$sid"))
                        }
                    } else {
                        $out.Add($line)
                    }
                }
                if (-not $found) {
                    $idx = ($out | Select-String -Pattern '^\[Privilege Rights\]' | Select-Object -First 1).LineNumber
                    if (-not $idx) { throw 'Privilege Rights section not found in secedit export.' }
                    $out.Insert($idx, ("{0} = *{1}" -f $Right, $sid))
                }
                Set-Content -LiteralPath $infImport -Value $out -Encoding Unicode
                $null = & secedit.exe /configure /db $db /cfg $infImport /areas USER_RIGHTS /log $log 2>&1
                if ($LASTEXITCODE -ne 0) { throw ("secedit configure failed with exit code {0}" -f $LASTEXITCODE) }
                return 'OK'
            } finally {
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        $account = if ($AccountOverride) { $AccountOverride } else { Get-ServiceAccountName $Name }
        if (-not $account) { $account = 'LocalSystem' }

        if ($WhatIfPreferred) {
            Add-Row 'Plan' 'WhatIf' ("Account={0}; Port={1}; ACL={2}; Firewall={3}; LogonRight={4}; PerfMon={5}" -f `
                $account, $Port, (-not $NoAcl), (-not $NoFirewall), $DoLogonRight, $DoPerfMon)
            return $rows
        }

        if (-not (Test-IsAdministrator)) {
            throw 'Administrator rights are required on the target to create windows_exporter access.'
        }

        $web = Join-Path $Root 'config\web-config.yml'
        $collectorDir = Join-Path $Root 'collector'
        $textDir = Join-Path $Root 'textfile_inputs'
        $logDir = Join-Path $Root 'log'

        if (-not $NoAcl) {
            if (-not (Test-Path -LiteralPath $Root)) {
                New-Item -Path $Root -ItemType Directory -Force | Out-Null
                Add-Row 'Create InstallRoot' 'OK' $Root
            }
            if (-not (Test-Path -LiteralPath $textDir)) {
                New-Item -Path $textDir -ItemType Directory -Force | Out-Null
                Add-Row 'Create textfile_inputs' 'OK' $textDir
            } else {
                Add-Row 'Create textfile_inputs' 'OK' 'Already exists'
            }
            if (-not (Test-Path -LiteralPath $collectorDir)) {
                New-Item -Path $collectorDir -ItemType Directory -Force | Out-Null
                Add-Row 'Create collector' 'OK' $collectorDir
            } else {
                Add-Row 'Create collector' 'OK' 'Already exists'
            }
            if (-not (Test-Path -LiteralPath $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                Add-Row 'Create log' 'OK' $logDir
            } else {
                Add-Row 'Create log' 'OK' 'Already exists'
            }

            Set-HardenedAcl -Path $Root -ServiceAccount $account -AllowServiceWrite:$false
            Set-HardenedAcl -Path $collectorDir -ServiceAccount $account -AllowServiceWrite:$false
            Set-HardenedAcl -Path $textDir -ServiceAccount $account -AllowServiceWrite:$true
            Set-HardenedAcl -Path $logDir -ServiceAccount $account -AllowServiceWrite:$true
            Add-Row 'ACL InstallRoot' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute (unless LocalSystem)'
            Add-Row 'ACL collector' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute (unless LocalSystem)'
            Add-Row 'ACL textfile_inputs' 'OK' 'Administrators+SYSTEM Full; service Modify (unless LocalSystem)'
            Add-Row 'ACL log' 'OK' 'Administrators+SYSTEM Full; service Modify for NSSM stdout/stderr (unless LocalSystem)'

            if (Test-Path -LiteralPath $web) {
                Set-HardenedAcl -Path $web -ServiceAccount $account -AllowServiceWrite:$false
                Add-Row 'ACL web-config.yml' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute (unless LocalSystem)'
            } else {
                Add-Row 'ACL web-config.yml' 'SKIP' 'File not found; deploy package first'
            }
        } else {
            Add-Row 'ACL' 'SKIP' '-SkipAcl was set'
        }

        if (-not $NoFirewall) {
            $ruleName = "Prometheus windows_exporter $Port"
            Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            New-NetFirewallRule -DisplayName $ruleName `
                -Direction Inbound -Protocol TCP -LocalPort $Port `
                -RemoteAddress $RemoteAddresses -Action Allow -Profile Any | Out-Null
            Add-Row 'Firewall' 'OK' ("{0} allows {1} -> TCP/{2}" -f $ruleName, ($RemoteAddresses -join ','), $Port)
        } else {
            Add-Row 'Firewall' 'SKIP' '-SkipFirewall was set'
        }

        $needLogon = $DoLogonRight -or (-not (Test-BuiltinServiceAccount $account) -and -not (Test-VirtualServiceAccount $account) -and $AccountOverride)
        if ($needLogon -and -not (Test-BuiltinServiceAccount $account) -and -not (Test-VirtualServiceAccount $account)) {
            try {
                $status = Grant-UserRight -Account $account -Right 'SeServiceLogonRight'
                Add-Row 'Log on as a service' $status $account
            } catch {
                Add-Row 'Log on as a service' 'FAIL' $_.Exception.Message
            }
        } elseif (Test-VirtualServiceAccount $account) {
            Add-Row 'Log on as a service' 'SKIP' ("Virtual account {0} is granted by SCM" -f $account)
        } else {
            Add-Row 'Log on as a service' 'SKIP' ("Account={0}" -f $account)
        }

        $hasSql = [bool]@(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(MSSQLSERVER|MSSQL\$.+)$' })
        if ($DoPerfMon -or ($hasSql -and -not (Test-BuiltinServiceAccount $account))) {
            if (Test-BuiltinServiceAccount $account) {
                Add-Row 'Performance Monitor Users' 'SKIP' 'Builtin service account already has counter access'
            } else {
                try {
                    $group = Get-LocalGroup -Name 'Performance Monitor Users' -ErrorAction Stop
                    $memberName = (Convert-AccountToNtAccount $account)
                    $exists = @(Get-LocalGroupMember -Group $group.Name -ErrorAction SilentlyContinue | Where-Object {
                        $_.Name -ieq $memberName -or $_.Name -like ("*\{0}" -f ($memberName.Split('\')[-1]))
                    }).Count -gt 0
                    if (-not $exists) {
                        Add-LocalGroupMember -Group $group.Name -Member $memberName -ErrorAction Stop
                        Add-Row 'Performance Monitor Users' 'OK' ("Added {0}" -f $memberName)
                    } else {
                        Add-Row 'Performance Monitor Users' 'OK' ("Already member: {0}" -f $memberName)
                    }
                } catch {
                    Add-Row 'Performance Monitor Users' 'FAIL' $_.Exception.Message
                }
            }
        } else {
            Add-Row 'Performance Monitor Users' 'SKIP' 'Pass -GrantPerformanceMonitorUsers for custom SQL service accounts'
        }

        Add-Row 'Note' 'INFO' 'SSAS DMV/Admin rights are granted inside Analysis Services, not by this script. See docs/fa/ssas-monitoring.md.'
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
    if ($targets.Count -eq 0) { [void]$targets.Add($env:COMPUTERNAME) }

    $all = @()
    foreach ($computer in ($targets | Select-Object -Unique)) {
        Write-Host "`n===== $computer =====" -ForegroundColor Yellow
        try {
            $run = $WhatIfPreference -or $PSCmdlet.ShouldProcess($computer, 'Create windows_exporter required access')
            if (-not $run) { continue }

            $args = @(
                $InstallRoot,
                $ServiceName,
                $ServiceAccount,
                $ListenPort,
                $PrometheusRemoteAddress,
                [bool]$GrantLogonAsService,
                [bool]$GrantPerformanceMonitorUsers,
                [bool]$SkipFirewall,
                [bool]$SkipAcl,
                [bool]$WhatIfPreference
            )

            if (Test-LocalComputerName $computer) {
                $rows = & $grantScript @args
            } else {
                $sessionArgs = @{ ComputerName = $computer; ErrorAction = 'Stop' }
                if ($Credential) { $sessionArgs.Credential = $Credential }
                Test-WSMan -ComputerName $computer -ErrorAction Stop | Out-Null
                $rows = Invoke-Command @sessionArgs -ScriptBlock $grantScript -ArgumentList $args
            }

            $all += @($rows)
            $rows | Select-Object ComputerName, Action, Status, Detail | Format-Table -AutoSize
        } catch {
            $err = [pscustomobject]@{
                ComputerName = $computer
                Action       = 'Set access'
                Status       = 'FAIL'
                Detail       = $_.Exception.Message
            }
            $all += $err
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($all.Count) {
        $summary = $all | Group-Object Status | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }
        Write-Host ("`nSummary: " + ($summary -join ', ')) -ForegroundColor Cyan
        if (@($all | Where-Object Status -eq 'FAIL').Count) { exit 1 }
    }
}
