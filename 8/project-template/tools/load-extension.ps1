[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ExtensionName,
    [string] $SourcePath,
    [switch] $Create,
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

if (-not (Test-Path -LiteralPath (Join-Path $SourcePath 'Configuration.xml') -PathType Leaf)) {
    throw "Extension source was not found: $SourcePath"
}

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
if ($Create) {
    # -AllExtensions создаёт отсутствующее расширение из подкаталога с его именем.
    $arguments += @('/LoadConfigFromFiles', (Split-Path -Parent $SourcePath), '-AllExtensions')
}
else {
    $arguments += @('/LoadConfigFromFiles', $SourcePath, '-Extension', $ExtensionName)
}
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\load-extension.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Extension '$ExtensionName' loaded from: $SourcePath"
