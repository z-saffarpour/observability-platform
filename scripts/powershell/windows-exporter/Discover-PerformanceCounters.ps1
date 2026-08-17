[CmdletBinding()]
param(
    [string]$OutputPath
)

$sets = Get-Counter -ListSet * -ErrorAction SilentlyContinue |
    Where-Object CounterSetName -Match 'MSOLAP|MSAS|Analysis|Report|Power BI|PBIRS' |
    Sort-Object CounterSetName

$result = foreach ($set in $sets) {
    foreach ($path in $set.Paths) {
        [pscustomobject]@{
            CounterSetName = $set.CounterSetName
            CounterPath = $path
        }
    }
}

if ($OutputPath) {
    $result | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
}

$result
