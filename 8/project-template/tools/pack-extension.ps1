[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ExtensionName,
    [string] $OutputDirectory,
    [string] $Version,
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

$sourcePath = Join-Path (Get-ProjectRoot) "src\cfe\$ExtensionName"
$configurationPath = Join-Path $sourcePath 'Configuration.xml'
if (-not (Test-Path -LiteralPath $configurationPath -PathType Leaf)) {
    throw "Extension source was not found: $sourcePath"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $configuration = [xml](Get-Content -LiteralPath $configurationPath -Raw -Encoding UTF8)
    $versionNode = $configuration.SelectSingleNode(
        "/*[local-name()='MetaDataObject']/*[local-name()='Configuration']/*[local-name()='Properties']/*[local-name()='Version']")
    if ($null -eq $versionNode -or [string]::IsNullOrWhiteSpace($versionNode.InnerText)) {
        throw "Extension version was not found in: $configurationPath"
    }
    $Version = $versionNode.InnerText
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path (Get-ProjectRoot) 'releases'
}
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$targetPath = Join-Path $OutputDirectory "$ExtensionName-$Version.cfe"
$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += @('/DumpCfg', $targetPath, '-Extension', $ExtensionName)
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\pack-extension.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Extension '$ExtensionName' packed to: $targetPath"
