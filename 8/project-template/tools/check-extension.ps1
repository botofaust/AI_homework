[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ExtensionName,
    [string] $UserName = $env:ONEC_USER,
    [string] $Password = $env:ONEC_PASSWORD,
    [switch] $IncorrectReferences
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$UserName = Resolve-UserName $UserName
$executable = Resolve-OneCExecutable $OneCExecutable
$ibPath = Resolve-InfoBasePath $InfoBasePath
if (-not (Test-Path -LiteralPath (Join-Path $ibPath '1Cv8.1CD') -PathType Leaf)) {
    throw "Infobase was not found: $ibPath"
}

$connectionArguments = @('DESIGNER', "/F$ibPath")
$connectionArguments += Get-AuthenticationArguments -UserName $UserName -Password $Password

$checkArguments = $connectionArguments + @('/CheckConfig', '-Extension', $ExtensionName, '-ThinClient', '-WebClient', '-Server', '-ExternalConnection')
if ($IncorrectReferences) {
    # В демо-БСП есть известные замечания в справке, поэтому по умолчанию не проверяем.
    $checkArguments += '-IncorrectReferences'
}
$checkLogPath = Join-Path (Get-ProjectRoot) 'var\logs\check-extension.log'
Invoke-OneC -Executable $executable -Arguments $checkArguments -LogPath $checkLogPath

$applyArguments = $connectionArguments + @('/CheckCanApplyConfigurationExtensions', '-Extension', $ExtensionName)
$applyLogPath = Join-Path (Get-ProjectRoot) 'var\logs\check-extension-applicability.log'
Invoke-OneC -Executable $executable -Arguments $applyArguments -LogPath $applyLogPath

Write-Host "Extension '$ExtensionName' check completed successfully."
