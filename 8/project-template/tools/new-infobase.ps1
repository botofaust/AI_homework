[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$executable = Resolve-OneCExecutable $OneCExecutable
$ibPath = Resolve-InfoBasePath $InfoBasePath

if (Test-Path -LiteralPath $ibPath) {
    $existing = Get-ChildItem -LiteralPath $ibPath -Force -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $existing) {
        throw "The infobase directory is not empty: $ibPath"
    }
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ibPath) | Out-Null
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\new-infobase.log'
$connection = "File=$ibPath;"

Invoke-OneC -Executable $executable -Arguments @('CREATEINFOBASE', $connection) -LogPath $logPath
Write-Host "Infobase created: $ibPath"
