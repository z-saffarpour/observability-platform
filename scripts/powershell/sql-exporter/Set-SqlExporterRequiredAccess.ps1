#Requires -Version 5.1
<#
.SYNOPSIS
  Creates the required local access for sql_exporter (ACL, firewall, rights).
.DESCRIPTION
  Applies least-privilege ACLs on the install root and web-config.yml; creates a
  scoped inbound firewall rule for the scrape port; optionally grants
  "Log on as a service" for a custom service account. SQL Server grants are NOT
  applied here — use scripts/sql/Create-SqlExporterLogin.sql. Audit afterward
  with Test-SqlExporterRequiredAccess.ps1.
.EXAMPLE
  .\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
    -PrometheusRemoteAddress 10.10.10.20 -WhatIf
.EXAMPLE
  .\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
    -PrometheusRemoteAddress 10.10.10.20,10.10.10.21
.EXAMPLE
  .\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
    -ComputerName SQL01 `
    -Credential (Get-Credential) `
    -ServiceAccount 'DOMAIN\SqlExporterAccount' `
    -PrometheusRemoteAddress 10.10.10.20 `
    -GrantLogonAsService
.EXAMPLE
  .\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
    -ComputerName SQL01 `
    -Credential (Get-Credential) `
    -ServiceAccount 'NT SERVICE\prometheus_sql_exporter' `
    -PrometheusRemoteAddress 10.10.10.20
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias('Computers')]
    [string[]]$ComputerName,

    [pscredential]$Credential,

    [string]$InstallRoot = 'C:\Program Files\Observability\PrometheusExporters\sql-exporter',

    [string]$ServiceName = 'prometheus_sql_exporter',

    [string]$ServiceAccount,

    [ValidateRange(1,65535)]
    [int]$ListenPort = 9399,

    [string[]]$PrometheusRemoteAddress,

    [switch]$GrantLogonAsService,

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

        function Add-Row([string]$Action, [string]$Status, [string]$Detail) {
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
            $escaped = $Service.Replace("'", "''")
            $svc = Get-CimInstance Win32_Service -Filter "Name='$escaped'" -ErrorAction SilentlyContinue
            if ($svc) { return $svc.StartName }
            $null
        }

        function Set-HardenedAcl {
            param(
                [string]$Path,
                [string]$ServiceAccount,
                [bool]$AllowServiceWrite = $false
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
            [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('BUILTIN\Administrators', 'FullControl', $inheritance, $propagation, 'Allow')))
            [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule('NT AUTHORITY\SYSTEM', 'FullControl', $inheritance, $propagation, 'Allow')))
            $svcNt = Convert-AccountToNtAccount $ServiceAccount
            if ($svcNt -and $svcNt -ne 'NT AUTHORITY\SYSTEM') {
                $right = if ($AllowServiceWrite) { 'Modify' } else { 'ReadAndExecute' }
                [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($svcNt, $right, $inheritance, $propagation, 'Allow')))
            }
            Set-Acl -LiteralPath $Path -AclObject $acl
        }

        function Grant-UserRight {
            param([string]$Account, [string]$Right)
            if (Test-BuiltinServiceAccount $Account) { return 'SKIP' }
            if (Test-VirtualServiceAccount $Account) { return 'SKIP' }
            $nt = Convert-AccountToNtAccount $Account
            $sid = ([System.Security.Principal.NTAccount]$nt).Translate([System.Security.Principal.SecurityIdentifier]).Value
            $tempDir = Join-Path $env:TEMP ('sqlexp-rights-' + [guid]::NewGuid().ToString('N'))
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
            Add-Row 'Plan' 'WhatIf' ("Account={0}; Port={1}; ACL={2}; Firewall={3}; LogonRight={4}" -f `
                    $account, $Port, (-not $NoAcl), (-not $NoFirewall), $DoLogonRight)
            return $rows
        }

        if (-not (Test-IsAdministrator)) {
            throw 'Administrator rights are required on the target to create sql_exporter access.'
        }

        $web = Join-Path $Root 'config\web-config.yml'
        $logDir = Join-Path $Root 'log'

        if (-not $NoAcl) {
            if (-not (Test-Path -LiteralPath $Root)) {
                New-Item -Path $Root -ItemType Directory -Force | Out-Null
                Add-Row 'Create InstallRoot' 'OK' $Root
            }
            if (-not (Test-Path -LiteralPath $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                Add-Row 'Create log' 'OK' $logDir
            }

            Set-HardenedAcl -Path $Root -ServiceAccount $account
            Add-Row 'ACL InstallRoot' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute (unless LocalSystem)'

            Set-HardenedAcl -Path $logDir -ServiceAccount $account -AllowServiceWrite:$true
            Add-Row 'ACL log' 'OK' 'Administrators+SYSTEM Full; service Modify for NSSM stdout/stderr (unless LocalSystem)'

            if (Test-Path -LiteralPath $web) {
                Set-HardenedAcl -Path $web -ServiceAccount $account
                Add-Row 'ACL web-config.yml' 'OK' 'Administrators+SYSTEM Full; service ReadAndExecute (unless LocalSystem)'
            } else {
                Add-Row 'ACL web-config.yml' 'SKIP' 'File not found; deploy package first'
            }
        } else {
            Add-Row 'ACL' 'SKIP' '-SkipAcl was set'
        }

        if (-not $NoFirewall) {
            $ruleName = "Prometheus sql_exporter $Port"
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

        Add-Row 'Note' 'INFO' 'SQL grants are applied with scripts/sql/Create-SqlExporterLogin.sql (sysadmin), not by this script.'
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
            if (-not $PSCmdlet.ShouldProcess($computer, 'Create sql_exporter required access')) { continue }

            if (Test-LocalComputerName $computer) {
                $result = & $grantScript $InstallRoot $ServiceName $ServiceAccount $ListenPort $PrometheusRemoteAddress `
                ([bool]$GrantLogonAsService) ([bool]$SkipFirewall) ([bool]$SkipAcl) ([bool]$WhatIfPreference)
            } else {
                $sessionParams = @{ ComputerName = $computer; ErrorAction = 'Stop' }
                if ($Credential) { $sessionParams.Credential = $Credential }
                $session = New-PSSession @sessionParams
                try {
                    $result = Invoke-Command -Session $session -ScriptBlock $grantScript -ArgumentList `
                        $InstallRoot, $ServiceName, $ServiceAccount, $ListenPort, $PrometheusRemoteAddress, `
                        ([bool]$GrantLogonAsService), ([bool]$SkipFirewall), ([bool]$SkipAcl), ([bool]$WhatIfPreference)
                } finally {
                    Remove-PSSession $session -ErrorAction SilentlyContinue
                }
            }
            $all += $result
            $result | Format-Table Action, Status, Detail -AutoSize | Out-String | Write-Host
        } catch {
            Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
            $all += [pscustomobject]@{
                ComputerName = $computer
                Action       = 'Session'
                Status       = 'FAIL'
                Detail       = $_.Exception.Message
            }
        }
    }

    if (@($all | Where-Object Status -eq 'FAIL').Count -gt 0) { exit 1 }
    exit 0
}
