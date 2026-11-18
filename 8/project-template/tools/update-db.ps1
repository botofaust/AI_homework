[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
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

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += '/UpdateDBCfg'
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\update-db.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host 'Database configuration updated.'
