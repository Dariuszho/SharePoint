# DownloadDependencies.ps1
# Downloads iTextSharp and BouncyCastle DLLs from NuGet

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Downloading PDF Solution Dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create temp folder
$tempDir = ".\temp_nuget"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Download iTextSharp (5.x is LGPL - free for commercial use)
# Note: iText 7+ is AGPL (requires open source) or commercial license
Write-Host "[1/2] Downloading iTextSharp 5.5.13.4 (latest LGPL version)..." -ForegroundColor Yellow
$itextUrl = "https://www.nuget.org/api/v2/package/iTextSharp/5.5.13.4"
$itextZip = "$tempDir\itextsharp.zip"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $itextUrl -OutFile $itextZip -UseBasicParsing
    Write-Host "  Downloaded!" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: Failed to download iTextSharp" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Manual download:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://www.nuget.org/packages/iTextSharp/5.5.13.3" -ForegroundColor White
    Write-Host "  2. Click 'Download package' on the right side" -ForegroundColor White
    Write-Host "  3. Rename .nupkg to .zip and extract" -ForegroundColor White
    Write-Host "  4. Copy lib\net40\itextsharp.dll to this folder" -ForegroundColor White
    exit 1
}

# Extract iTextSharp
Write-Host "  Extracting..." -ForegroundColor Yellow
$itextExtract = "$tempDir\itextsharp"
Expand-Archive -Path $itextZip -DestinationPath $itextExtract -Force

# Find the DLL (structure varies by package version)
$itextDll = Get-ChildItem -Path $itextExtract -Recurse -Filter "itextsharp.dll" | Select-Object -First 1
if ($itextDll) {
    Copy-Item $itextDll.FullName -Destination ".\itextsharp.dll" -Force
    Write-Host "  itextsharp.dll ready!" -ForegroundColor Green
}
else {
    Write-Host "  ERROR: itextsharp.dll not found in package" -ForegroundColor Red
    Write-Host "  Listing package contents:" -ForegroundColor Yellow
    Get-ChildItem -Path $itextExtract -Recurse | ForEach-Object { Write-Host "    $($_.FullName)" }
    exit 1
}

# Download BouncyCastle
Write-Host "[2/2] Downloading BouncyCastle 1.8.9..." -ForegroundColor Yellow
$bcUrl = "https://www.nuget.org/api/v2/package/BouncyCastle/1.8.9"
$bcZip = "$tempDir\bouncycastle.zip"

try {
    Invoke-WebRequest -Uri $bcUrl -OutFile $bcZip -UseBasicParsing
    Write-Host "  Downloaded!" -ForegroundColor Green
}
catch {
    Write-Host "  ERROR: Failed to download BouncyCastle" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Manual download:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://www.nuget.org/packages/BouncyCastle/1.8.9" -ForegroundColor White
    Write-Host "  2. Click 'Download package' on the right side" -ForegroundColor White
    Write-Host "  3. Rename .nupkg to .zip and extract" -ForegroundColor White
    Write-Host "  4. Copy lib\BouncyCastle.Crypto.dll to this folder" -ForegroundColor White
    exit 1
}

# Extract BouncyCastle
Write-Host "  Extracting..." -ForegroundColor Yellow
$bcExtract = "$tempDir\bouncycastle"
Expand-Archive -Path $bcZip -DestinationPath $bcExtract -Force

# Find the DLL (structure varies by package version)
$bcDll = Get-ChildItem -Path $bcExtract -Recurse -Filter "BouncyCastle.Crypto.dll" | Select-Object -First 1
if ($bcDll) {
    Copy-Item $bcDll.FullName -Destination ".\BouncyCastle.Crypto.dll" -Force
    Write-Host "  BouncyCastle.Crypto.dll ready!" -ForegroundColor Green
}
else {
    Write-Host "  ERROR: BouncyCastle.Crypto.dll not found in package" -ForegroundColor Red
    Write-Host "  Listing package contents:" -ForegroundColor Yellow
    Get-ChildItem -Path $bcExtract -Recurse | ForEach-Object { Write-Host "    $($_.FullName)" }
    exit 1
}

# Cleanup
Write-Host ""
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item $tempDir -Recurse -Force

# Verify
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Dependencies downloaded successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor White
Write-Host "  - itextsharp.dll" -ForegroundColor Cyan
Write-Host "  - BouncyCastle.Crypto.dll" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Run .\CreateWSP.ps1 to build the solution" -ForegroundColor Yellow
Write-Host ""