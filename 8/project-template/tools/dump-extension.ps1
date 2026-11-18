[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ExtensionName,
    [string] $SourcePath,
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

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path (Get-ProjectRoot) "src\cfe\$ExtensionName"
}
$SourcePath = Resolve-ProjectPath -Path $SourcePath
New-Item -ItemType Directory -Force -Path $SourcePath | Out-Null

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += @('/DumpConfigToFiles', $SourcePath, '-Extension', $ExtensionName)
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\dump-extension.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Extension '$ExtensionName' dumped to XML: $SourcePath"
