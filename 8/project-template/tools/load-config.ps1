[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [string] $UserName = $env:ONEC_USER,
    [string] $Password = $env:ONEC_PASSWORD,
    [string] $SourcePath
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$UserName = Resolve-UserName $UserName
$executable = Resolve-OneCExecutable $OneCExecutable
$ibPath = Resolve-InfoBasePath $InfoBasePath
if (-not (Test-Path -LiteralPath (Join-Path $ibPath '1Cv8.1CD') -PathType Leaf)) {
    throw "Infobase was not found: $ibPath"
}

$source = Resolve-ProjectPath -Path $SourcePath -DefaultRelativePath 'src\cf'
if (-not (Test-Path -LiteralPath (Join-Path $source 'Configuration.xml') -PathType Leaf)) {
    throw "Configuration.xml was not found in $source. Dump the configuration first."
}

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += @('/LoadConfigFromFiles', $source)
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\load-config.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Configuration loaded from: $source"
