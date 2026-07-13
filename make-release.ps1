# make-release.ps1
# Packages the addon files from the project root into Chronicles-<version>.zip,
# laid out as an installable AddOns/Chronicles/ folder (dev-only files excluded).
# Usage: .\make-release.ps1 [-OutDir <path>]

param(
    [string]$OutDir = (Join-Path $PSScriptRoot ".build")
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$addonName   = "Chronicles"
$tocFile     = Join-Path $projectRoot "$addonName.toc"

# --- Read version from TOC --------------------------------------------------
$versionLine = Select-String -Path $tocFile -Pattern "^## Version:\s*(.+)" |
               Select-Object -First 1
if (-not $versionLine) {
    Write-Error "Could not find '## Version:' in $tocFile"
    exit 1
}
$version = $versionLine.Matches[0].Groups[1].Value.Trim()
# The TOC version may already carry a leading 'v' (e.g. v2.0.1); don't double it.
$tag = if ($version -match '^[vV]') { $version } else { "v$version" }

$zipName  = "$addonName-$tag.zip"
$zipPath  = Join-Path $OutDir $zipName
$stageDir = Join-Path $projectRoot $addonName

# --- Files and folders to include in the release ----------------------------
# Runtime code/data + shipped docs. Dev-only paths (.git, .github, .vscode,
# .claude, docs, refs, Tests, ANALYSIS.md, TODO, this script) are omitted.
$includes = @(
    "$addonName.lua",
    "$addonName.toc",
    "$addonName.xml",
    "Constants.lua",
    "LICENCE",
    "Readme.md",
    "CHANGELOG.txt",
    "PLUGINS.md",
    "Art",
    "Core",
    "DB",
    "Images",
    "Libs",
    "Locales",
    "UI"
)

# Subpaths to prune from the staged copy after copying (dev-only source assets).
$prune = @(
    "Art\Raw"
)

# --- Clean previous artifacts -----------------------------------------------
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
if (Test-Path $zipPath)  { Remove-Item $zipPath  -Force }

# --- Stage ------------------------------------------------------------------
Write-Host "Staging files from project root -> $addonName/"
New-Item -ItemType Directory -Path $stageDir | Out-Null

foreach ($entry in $includes) {
    $src = Join-Path $projectRoot $entry
    if (-not (Test-Path $src)) {
        Write-Warning "Missing: $entry - skipped"
        continue
    }
    Copy-Item -Path $src -Destination $stageDir -Recurse
}

foreach ($entry in $prune) {
    $target = Join-Path $stageDir $entry
    if (Test-Path $target) {
        Write-Host "Pruning dev-only path: $entry"
        Remove-Item $target -Recurse -Force
    }
}

# --- Zip --------------------------------------------------------------------
Write-Host "Creating $zipName ..."
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
Compress-Archive -Path $stageDir -DestinationPath $zipPath

# --- Cleanup ----------------------------------------------------------------
Remove-Item $stageDir -Recurse -Force

Write-Host "Release ready: $zipPath"
