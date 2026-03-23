# CreateWSP.ps1
# Creates SharePoint WSP package for PDF Solution (Server-Side)

param(
    [string]$OutputPath = ".\SharePointPdfSolution.wsp"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SharePoint PDF Solution - WSP Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check for required DLLs
Write-Host "[1/5] Checking dependencies..." -ForegroundColor Yellow

if (-not (Test-Path "itextsharp.dll")) {
    Write-Host "ERROR: itextsharp.dll not found. Run .\DownloadDependencies.ps1 first" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "BouncyCastle.Crypto.dll")) {
    Write-Host "ERROR: BouncyCastle.Crypto.dll not found. Run .\DownloadDependencies.ps1 first" -ForegroundColor Red
    exit 1
}
Write-Host "  All dependencies found!" -ForegroundColor Green

# Step 2: Compile C# code
Write-Host "[2/5] Compiling C# handler..." -ForegroundColor Yellow

$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $cscPath)) {
    $cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path $cscPath)) {
    Write-Host "ERROR: C# compiler not found." -ForegroundColor Red
    exit 1
}

& $cscPath /target:library /out:SharePointPdfHandler.dll /reference:itextsharp.dll /reference:System.Web.dll /reference:System.Web.Extensions.dll /reference:System.dll PdfGenerator.ashx.cs

if (-not (Test-Path "SharePointPdfHandler.dll")) {
    Write-Host "ERROR: Compilation failed!" -ForegroundColor Red
    exit 1
}
Write-Host "  Compilation successful!" -ForegroundColor Green

# Step 3: Create staging folder with correct WSP structure
Write-Host "[3/5] Creating WSP structure..." -ForegroundColor Yellow

$stagingDir = ".\wsp_staging"
if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force }

# Create folder structure
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
New-Item -ItemType Directory -Path "$stagingDir\PdfHandlerFeature" -Force | Out-Null
New-Item -ItemType Directory -Path "$stagingDir\LAYOUTS\SharePointPdfSolution" -Force | Out-Null

# Copy files to staging
Copy-Item "manifest.xml" -Destination $stagingDir
Copy-Item "SharePointPdfHandler.dll" -Destination $stagingDir
Copy-Item "itextsharp.dll" -Destination $stagingDir
Copy-Item "BouncyCastle.Crypto.dll" -Destination $stagingDir
Copy-Item "PdfHandlerFeature\Feature.xml" -Destination "$stagingDir\PdfHandlerFeature\"
Copy-Item "LAYOUTS\SharePointPdfSolution\PdfGenerator.ashx" -Destination "$stagingDir\LAYOUTS\SharePointPdfSolution\"

Write-Host "  Structure created!" -ForegroundColor Green

# Step 4: Create DDF file and build CAB
Write-Host "[4/5] Building WSP (CAB) file..." -ForegroundColor Yellow

# Change to staging directory for makecab
Push-Location $stagingDir

$ddfContent = @"
.OPTION EXPLICIT
.Set CabinetNameTemplate=SharePointPdfSolution.wsp
.Set DiskDirectory1=.
.Set CompressionType=MSZIP
.Set UniqueFiles=OFF
.Set Cabinet=ON
.Set MaxDiskSize=0
.Set DestinationDir=

manifest.xml
SharePointPdfHandler.dll
itextsharp.dll
BouncyCastle.Crypto.dll

.Set DestinationDir=PdfHandlerFeature
PdfHandlerFeature\Feature.xml Feature.xml

.Set DestinationDir=LAYOUTS\SharePointPdfSolution
LAYOUTS\SharePointPdfSolution\PdfGenerator.ashx PdfGenerator.ashx
"@

$ddfContent | Out-File -FilePath "package.ddf" -Encoding ASCII

# Run makecab
$makecabOutput = & makecab /F package.ddf 2>&1
$makecabExitCode = $LASTEXITCODE

# Return to original directory
Pop-Location

if ($makecabExitCode -ne 0) {
    Write-Host "ERROR: makecab failed" -ForegroundColor Red
    Write-Host $makecabOutput
    exit 1
}

# Step 5: Move WSP to output location
Write-Host "[5/5] Finalizing..." -ForegroundColor Yellow

# Find the WSP file
$wspFile = Get-ChildItem -Path $stagingDir -Filter "*.wsp" -Recurse | Select-Object -First 1

if ($wspFile) {
    Move-Item $wspFile.FullName -Destination $OutputPath -Force
    Write-Host "  WSP file created!" -ForegroundColor Green
}
else {
    Write-Host "ERROR: WSP file not found after makecab" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "SharePointPdfHandler.dll" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "WSP created successfully!" -ForegroundColor Green
Write-Host "File: $((Get-Item $OutputPath).FullName)" -ForegroundColor White
Write-Host "Size: $([math]::Round((Get-Item $OutputPath).Length / 1KB, 2)) KB" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
$fullWspPath = (Get-Item $OutputPath).FullName
Write-Host "DEPLOYMENT:" -ForegroundColor Cyan
Write-Host "  Add-SPSolution -LiteralPath `"$fullWspPath`"" -ForegroundColor Yellow
Write-Host '  Install-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Force' -ForegroundColor Yellow
Write-Host ""
Write-Host "  (Replace http://your-sharepoint-site with your actual web application URL)" -ForegroundColor Gray
Write-Host ""
Write-Host "TEST:" -ForegroundColor Cyan
Write-Host '  http://your-site/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx?test=1' -ForegroundColor Yellow
Write-Host ""