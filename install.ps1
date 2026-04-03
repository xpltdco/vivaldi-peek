<#
.SYNOPSIS
    Installs vivaldi-peek: auto-collapsing vertical tabs for Vivaldi.

.DESCRIPTION
    1. Copies custom CSS to Vivaldi's User Data directory.
    2. Enables the "Allow CSS modifications" experiment flag in Preferences.
    3. Sets the CSS folder path in Preferences.
    Vivaldi must be CLOSED before running this script.
    All changes are in User Data, so they persist through Vivaldi updates.

.PARAMETER Uninstall
    Remove vivaldi-peek and revert Preferences changes.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Uninstall
#>

param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# ── Paths ────────────────────────────────────────────────────────────────────

$VivaldiUserData = "$env:LOCALAPPDATA\Vivaldi\User Data"
$PrefsFile       = "$VivaldiUserData\Default\Preferences"
$CssDest         = "$VivaldiUserData\vivaldi-peek-css"
$CssSource       = "$PSScriptRoot\css"

# ── Preflight checks ────────────────────────────────────────────────────────

if (-not (Test-Path $PrefsFile)) {
    Write-Error "Vivaldi Preferences not found at $PrefsFile. Is Vivaldi installed?"
    exit 1
}

# Check if Vivaldi is running
$vivaldi = Get-Process -Name "vivaldi" -ErrorAction SilentlyContinue
if ($vivaldi) {
    Write-Error "Vivaldi is currently running. Please close it before running this script."
    exit 1
}

# ── Uninstall ────────────────────────────────────────────────────────────────

if ($Uninstall) {
    Write-Host "Uninstalling vivaldi-peek..." -ForegroundColor Yellow

    # Remove CSS folder
    if (Test-Path $CssDest) {
        Remove-Item -Recurse -Force $CssDest
        Write-Host "  Removed $CssDest" -ForegroundColor Gray
    }

    # Revert Preferences
    $prefs = Get-Content $PrefsFile -Raw | ConvertFrom-Json

    if ($prefs.vivaldi.features.PSObject.Properties["css_mods"]) {
        $prefs.vivaldi.features.PSObject.Properties.Remove("css_mods")
    }

    if ($prefs.vivaldi.PSObject.Properties["appearance"]) {
        if ($prefs.vivaldi.appearance.PSObject.Properties["css_ui_mods_directory"]) {
            $prefs.vivaldi.appearance.PSObject.Properties.Remove("css_ui_mods_directory")
        }
        # Remove appearance object if now empty
        if (($prefs.vivaldi.appearance.PSObject.Properties | Measure-Object).Count -eq 0) {
            $prefs.vivaldi.PSObject.Properties.Remove("appearance")
        }
    }

    $prefs | ConvertTo-Json -Depth 100 -Compress | Set-Content $PrefsFile -Encoding UTF8
    Write-Host "  Reverted Preferences" -ForegroundColor Gray
    Write-Host ""
    Write-Host "vivaldi-peek uninstalled. Restart Vivaldi to see the change." -ForegroundColor Green
    exit 0
}

# ── Install ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  vivaldi-peek installer" -ForegroundColor Cyan
Write-Host "  Auto-collapsing vertical tabs for Vivaldi" -ForegroundColor Gray
Write-Host ""

# Step 1: Copy CSS files
Write-Host "[1/3] Copying CSS files..." -ForegroundColor White
if (Test-Path $CssDest) {
    Remove-Item -Recurse -Force $CssDest
}
Copy-Item -Recurse $CssSource $CssDest
Write-Host "  -> $CssDest" -ForegroundColor Gray

# Step 2: Backup Preferences
Write-Host "[2/3] Backing up Preferences..." -ForegroundColor White
$backupPath = "$PrefsFile.vivaldi-peek-backup"
Copy-Item $PrefsFile $backupPath -Force
Write-Host "  -> $backupPath" -ForegroundColor Gray

# Step 3: Update Preferences
Write-Host "[3/3] Configuring Vivaldi..." -ForegroundColor White

$prefs = Get-Content $PrefsFile -Raw | ConvertFrom-Json

# Enable css_mods experiment flag
if (-not $prefs.vivaldi.features.PSObject.Properties["css_mods"]) {
    $prefs.vivaldi.features | Add-Member -NotePropertyName "css_mods" -NotePropertyValue $true
    Write-Host "  Enabled CSS modifications experiment flag" -ForegroundColor Gray
} else {
    $prefs.vivaldi.features.css_mods = $true
    Write-Host "  CSS modifications experiment flag already present, ensured enabled" -ForegroundColor Gray
}

# Set CSS folder path (Vivaldi expects Windows-style backslash path)
$cssDestWin = $CssDest.Replace("/", "\")

if (-not $prefs.vivaldi.PSObject.Properties["appearance"]) {
    $prefs.vivaldi | Add-Member -NotePropertyName "appearance" -NotePropertyValue ([PSCustomObject]@{
        css_ui_mods_directory = $cssDestWin
    })
} elseif (-not $prefs.vivaldi.appearance.PSObject.Properties["css_ui_mods_directory"]) {
    $prefs.vivaldi.appearance | Add-Member -NotePropertyName "css_ui_mods_directory" -NotePropertyValue $cssDestWin
} else {
    $prefs.vivaldi.appearance.css_ui_mods_directory = $cssDestWin
}
Write-Host "  Set CSS directory to: $cssDestWin" -ForegroundColor Gray

# Write Preferences back
$prefs | ConvertTo-Json -Depth 100 -Compress | Set-Content $PrefsFile -Encoding UTF8

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "vivaldi-peek installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Vivaldi" -ForegroundColor White
Write-Host "  2. Make sure your tabs are set to vertical (left or right side)" -ForegroundColor White
Write-Host "     Settings > Tabs > Tab Bar Position > Left or Right" -ForegroundColor Gray
Write-Host "  3. Your tabs will now auto-hide and reveal on hover" -ForegroundColor White
Write-Host ""
Write-Host "To uninstall: .\install.ps1 -Uninstall" -ForegroundColor Gray
Write-Host ""
