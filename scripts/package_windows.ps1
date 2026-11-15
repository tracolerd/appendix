# ==============================================================================
# Appendix — Windows Packaging Script (Portable Distribution)
# ==============================================================================

[CmdletBinding()]
param (
    [string]$Version = "0.1.0"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DistDir = Join-Path $RootDir "dist\appendix-windows-x64-v$Version"
$ZipFile = Join-Path $RootDir "dist\appendix-windows-x64-v$Version.zip"

Write-Host "=== Packaging Appendix for Windows (v$Version) ===" -ForegroundColor Cyan

# 1. Ensure fresh release DLL is compiled
Write-Host "--> Checking Rust release core DLL..." -ForegroundColor Yellow
$DllPath = Join-Path $RootDir "rust\target\release\appendix_core.dll"
if (-not (Test-Path $DllPath)) {
    Write-Host "Compiling appendix_core.dll..."
    cmd.exe /c "call ""C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"" && cd /d ""$RootDir\rust"" && cargo build --release"
}

# 2. Prepare Distribution Directory
if (Test-Path $DistDir) {
    Remove-Item -Path $DistDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

# 3. Copy Native DLL and Model Manifest
Write-Host "--> Copying core binaries and manifests..." -ForegroundColor Yellow
Copy-Item -Path $DllPath -Destination $DistDir -Force
Copy-Item -Path (Join-Path $RootDir "models\model_manifest.json") -Destination $DistDir -Force
Copy-Item -Path (Join-Path $RootDir "models\README.md") -Destination (Join-Path $DistDir "MODELS_GUIDE.md") -Force
Copy-Item -Path (Join-Path $RootDir "LICENSE") -Destination $DistDir -Force
Copy-Item -Path (Join-Path $RootDir "README.md") -Destination $DistDir -Force

# 4. Create Launcher Script
$LauncherScript = @"
@echo off
setlocal
set PATH=%~dp0;%PATH%
echo Starting Appendix Offline Writing Assistant...
start "" "%~dp0appendix.exe"
"@
Set-Content -Path (Join-Path $DistDir "run_appendix.bat") -Value $LauncherScript

# 5. Compress to ZIP
Write-Host "--> Generating distribution archive: $ZipFile" -ForegroundColor Yellow
if (Test-Path $ZipFile) {
    Remove-Item -Path $ZipFile -Force
}
Compress-Archive -Path "$DistDir\*" -DestinationPath $ZipFile -Force

$Hash = Get-FileHash -Path $ZipFile -Algorithm SHA256
Write-Host "✓ Windows package generated successfully!" -ForegroundColor Green
Write-Host "  Archive: $ZipFile"
Write-Host "  SHA-256: $($Hash.Hash)"
