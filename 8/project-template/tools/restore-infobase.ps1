[CmdletBinding()]
param(
    [string] $OneCExecutable,
    [string] $InfoBasePath,
    [string] $TemplatePath,
    [string] $UserName = $env:ONEC_USER,
    [string] $Password = $env:ONEC_PASSWORD,
    [switch] $Force
)

. (Join-Path $PSScriptRoot 'Common.ps1')

function Resolve-TemplatePath {
    param([string] $ExplicitPath)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $resolved = Resolve-ProjectPath -Path $ExplicitPath
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw "Template file was not found: $resolved"
        }
        return $resolved
    }

    $root = Get-ProjectRoot
    $candidates = @()
    $rootTemplates = Get-ChildItem -LiteralPath $root -Filter '*.dt' -File -ErrorAction SilentlyContinue
    if ($null -ne $rootTemplates) {
        $candidates += $rootTemplates
    }

    $templateDirectory = Join-Path $root 'var\templates'
    if (Test-Path -LiteralPath $templateDirectory -PathType Container) {
        $localTemplates = Get-ChildItem -LiteralPath $templateDirectory -Filter '*.dt' -File -ErrorAction SilentlyContinue
        if ($null -ne $localTemplates) {
            $candidates += $localTemplates
        }
    }

    if ($candidates.Count -eq 0) {
        throw 'No .dt template found. Put the template in the project root or var/templates, or pass -TemplatePath.'
    }
    if ($candidates.Count -gt 1) {
        throw "Multiple .dt templates found. Pass -TemplatePath explicitly:`n$($candidates.FullName -join "`n")"
    }

    return $candidates[0].FullName
}

$executable = Resolve-OneCExecutable $OneCExecutable
$ibPath = Resolve-InfoBasePath $InfoBasePath
$template = Resolve-TemplatePath $TemplatePath
$databaseFile = Join-Path $ibPath '1Cv8.1CD'

if (Test-Path -LiteralPath $databaseFile -PathType Leaf) {
    if (-not $Force) {
        throw "Infobase already contains data: $ibPath. Use -Force to overwrite it from the template."
    }
}
else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ibPath) | Out-Null
    $createLog = Join-Path (Get-ProjectRoot) 'var\logs\restore-create.log'
    Invoke-OneC -Executable $executable -Arguments @('CREATEINFOBASE', "File=$ibPath;") -LogPath $createLog
}

$arguments = @('DESIGNER', "/F$ibPath")
$arguments += Get-AuthenticationArguments -UserName $UserName -Password $Password
$arguments += @('/RestoreIB', $template)
$logPath = Join-Path (Get-ProjectRoot) 'var\logs\restore-infobase.log'

Invoke-OneC -Executable $executable -Arguments $arguments -LogPath $logPath
Write-Host "Infobase restored from: $template"
