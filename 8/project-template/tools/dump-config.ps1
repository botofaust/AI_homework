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
New-Item -ItemType Directory -Force -Path $source | Out-Null

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += @('/DumpConfigToFiles', $source)
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\dump-config.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Configuration dumped to: $source"
