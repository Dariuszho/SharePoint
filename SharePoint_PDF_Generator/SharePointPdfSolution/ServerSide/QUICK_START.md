# Quick Start Guide - SharePoint PDF Solution

## Prerequisites

- SharePoint 2016 on-premises (or 2013/2019)
- .NET Framework 4.5+ (C# 5 compatible)
- Farm Administrator access
- PowerShell execution enabled

---

## Step 1: Download Dependencies

Run the PowerShell script to automatically download required DLLs:

```powershell
cd SharePointPdfSolution\ServerSide
.\DownloadDependencies.ps1
```

This downloads:
- `itextsharp.dll` (iTextSharp 5.5.13.4 - LGPL license)
- `BouncyCastle.Crypto.dll` (BouncyCastle 1.8.9)

**Manual alternative:** Download from NuGet, rename `.nupkg` to `.zip`, extract:
- https://www.nuget.org/packages/iTextSharp/5.5.13.4 → `lib/net40/itextsharp.dll`
- https://www.nuget.org/packages/BouncyCastle/1.8.9 → `lib/BouncyCastle.Crypto.dll`

---

## Step 2: Build WSP Package

```powershell
.\CreateWSP.ps1
```

This will:
1. Check dependencies exist
2. Compile `PdfGenerator.ashx.cs` using .NET Framework compiler
3. Create WSP structure with manifest, feature, and assemblies
4. Package into `SharePointPdfSolution.wsp`

**Output:** `SharePointPdfSolution.wsp` in the ServerSide folder

---

## Step 3: Deploy to SharePoint

Copy the WSP to your SharePoint server, then run in **SharePoint Management Shell**:

```powershell
# Add the solution
Add-SPSolution -LiteralPath "C:\path\to\SharePointPdfSolution.wsp"

# Deploy to web application (replace URL with your actual web app)
Install-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Force
```

**Note:** Solution deploys to WebApplication bin folder (not GAC) - no assembly signing required.

---

## Step 4: Verify Installation

Open in browser:
```
http://your-sharepoint-site/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx?test=1
```

Expected response:
```json
{"status":"ok","message":"PDF Generator is running"}
```

---

## Step 5: Configure Example Pages

1. Copy ASPX files from `Examples/` folder to your SharePoint site (Site Pages or document library)

2. Edit each file and update `TARGET_LIBRARY` to your document library path:
```javascript
var TARGET_LIBRARY = '/sites/yoursite/Shared Documents/';
```

3. Test by filling out a form and clicking "Generate PDF"

---

## Updating the Solution

To update after code changes:

```powershell
# Retract current solution
Uninstall-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Confirm:$false

# Wait for retraction to complete
Start-Sleep -Seconds 10

# Remove solution
Remove-SPSolution -Identity SharePointPdfSolution.wsp -Confirm:$false

# Rebuild and redeploy
.\CreateWSP.ps1
Add-SPSolution -LiteralPath ".\SharePointPdfSolution.wsp"
Install-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Force
```

---

## Troubleshooting

| Issue                      | Solution                                                                                       |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| "Could not load assembly"  | Run `iisreset` on SharePoint server                                                            |
| Handler returns 500 error  | Check ULS logs: `C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\LOGS` |
| Hebrew text not displaying | Ensure Arial font exists: `C:\Windows\Fonts\arial.ttf`                                         |
| PDF empty or corrupted     | Check browser F12 → Network tab for request/response                                           |

---

## How It Works

```
[Browser Form] → [POST JSON] → [C# Handler] → [PDF with RTL] → [Upload to SharePoint]
```

1. Client (ASPX page) collects form data
2. Client sends JSON POST to `/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx`
3. Server generates PDF using iTextSharp with proper RTL/Hebrew support
4. Server returns PDF as base64
5. Client converts to blob and uploads to SharePoint library via REST API
