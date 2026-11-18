[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [string] $DestinationPath,
    [string] $UserName = $env:ONEC_USER,
    [string] $Password = $env:ONEC_PASSWORD
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$UserName = Resolve-UserName $UserName
$executable = Resolve-OneCExecutable $OneCExecutable
$ibPath = Resolve-InfoBasePath $InfoBasePath
if (-not (Test-Path -LiteralPath (Join-Path $ibPath '1Cv8.1CD') -PathType Leaf)) {
    throw "Infobase was not found: $ibPath"
}

if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $DestinationPath = "var\backups\ib-$timestamp.dt"
}
$destination = Resolve-ProjectPath -Path $DestinationPath
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += @('/DumpIB', $destination)
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\backup-infobase.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Infobase backup created: $destination"
