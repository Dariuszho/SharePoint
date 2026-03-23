# SharePoint PDF Generator

Generate PDFs from SharePoint forms with full RTL/Hebrew/Arabic support. PDFs are automatically saved to SharePoint document libraries without print dialogs.

## Features

- ✅ Full Hebrew, Arabic, and RTL language support
- ✅ Mixed text (Hebrew + English + Numbers) displays correctly
- ✅ No print dialog - direct save to SharePoint library
- ✅ Image attachments embedded in PDF
- ✅ Works with SharePoint 2016 on-premises
- ✅ Free for commercial use (LGPL license)

## How It Works

```
[Browser Form] → [POST JSON] → [C# Handler] → [PDF with RTL] → [Upload to SharePoint]
```

This solution uses a server-side C# handler with iTextSharp library to generate PDFs. The browser collects form data and sends it to the handler, which generates the PDF and returns it for upload to SharePoint.

---

## Quick Start

### Step 1: Dependencies (DLLs Included)

The required DLLs are already included in the project:
- `itextsharp.dll` (iTextSharp 5.5.13.4)
- `BouncyCastle.Crypto.dll` (BouncyCastle 1.8.9)

**Alternative download method:** If you need to re-download the DLLs (e.g., due to security policies, firewall restrictions, or file corruption), run:

```powershell
cd SharePointPdfSolution\ServerSide
.\DownloadDependencies.ps1
```

Or manually download from NuGet (rename `.nupkg` to `.zip` and extract):
- [iTextSharp 5.5.13.4](https://www.nuget.org/packages/iTextSharp/5.5.13.4) → `lib/net40/itextsharp.dll`
- [BouncyCastle 1.8.9](https://www.nuget.org/packages/BouncyCastle/1.8.9) → `lib/BouncyCastle.Crypto.dll`

### Step 2: Build WSP Package

```powershell
cd SharePointPdfSolution\ServerSide
.\CreateWSP.ps1
```

This script:
1. Checks that dependencies exist
2. Compiles `PdfGenerator.ashx.cs` using .NET Framework C# compiler
3. Creates WSP package structure (manifest, feature, assemblies)
4. Outputs `SharePointPdfSolution.wsp`

### Step 3: Deploy to SharePoint

Copy the WSP file to your SharePoint server, then run in **SharePoint Management Shell**:

```powershell
# Add the solution to farm
Add-SPSolution -LiteralPath "C:\path\to\SharePointPdfSolution.wsp"

# Deploy to your web application
Install-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Force
```

**Note:** Replace `http://your-sharepoint-site` with your actual web application URL. Solution deploys to WebApplication bin folder (not GAC).

### Step 4: Verify Installation

Open in browser:
```
http://your-site/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx?test=1
```

Expected response:
```json
{"status":"ok","message":"PDF Generator is running"}
```

### Step 5: Configure Example Pages

1. Copy ASPX files from `SharePointPdfSolution/ServerSide/Examples/` to your SharePoint site

2. Edit each file and update `TARGET_LIBRARY` to your document library:
```javascript
var TARGET_LIBRARY = '/sites/yoursite/Shared Documents/';
```

3. Test by filling out a form and clicking the generate button

---

## Project Structure

```
SharePointPdfSolution/
└── ServerSide/
    ├── DownloadDependencies.ps1  # Downloads iTextSharp and BouncyCastle DLLs
    ├── CreateWSP.ps1             # Compiles code and creates WSP package
    ├── PdfGenerator.ashx.cs      # C# PDF generation handler
    ├── manifest.xml              # WSP manifest
    ├── QUICK_START.md            # Quick reference guide
    ├── Examples/
    │   ├── example-simple.aspx           # Simple form with fields
    │   ├── example-html-content.aspx     # Document with sections and table
    │   └── example-with-attachments.aspx # Form with image attachments
    ├── LAYOUTS/
    │   └── SharePointPdfSolution/
    │       └── PdfGenerator.ashx         # Handler entry point
    └── PdfHandlerFeature/
        └── Feature.xml                   # SharePoint feature definition
```

---

## Examples

### Simple Form (`example-simple.aspx`)
Basic form with name, email, department, and comments fields. Supports Hebrew/RTL input.

### Document Content (`example-html-content.aspx`)
Converts structured content (sections, lists, tables) to PDF with full Hebrew support.

### Form with Attachments (`example-with-attachments.aspx`)
Form that embeds images directly into the PDF. Non-image files are uploaded separately to SharePoint.

---

## Configuration

### Change Target Library

In each ASPX file, update the library path:
```javascript
var TARGET_LIBRARY = '/sites/yoursite/YourLibrary/';
```

### Change PDF Title

In the form data sent to the handler:
```javascript
var formData = {
    title: 'Your Custom Title / כותרת מותאמת',
    // ... other fields
};
```

### Filename Format

PDFs are saved with date suffix: `DocumentName_22.03.2026.pdf`

---

## Updating the Solution

To update after code changes:

```powershell
# Retract current solution
Uninstall-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Confirm:$false

# Wait for retraction
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

### "Could not load assembly 'itextsharp'"
- Run `iisreset` on SharePoint server
- Verify DLLs are deployed to the web application bin folder

### Handler returns 500 error
- Check ULS logs: `C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\LOGS`
- Error details are logged server-side (not exposed to client for security)

### Hebrew text not displaying
- Ensure Arial or Arial Unicode MS font is installed on SharePoint server
- Check `C:\Windows\Fonts\arial.ttf` exists

### PDF empty or corrupted
- Check browser F12 → Network tab for request/response data
- Verify JSON format in request body

---

## Requirements

- SharePoint 2016 on-premises (or 2013/2019)
- .NET Framework 4.5+ (C# 5 compatible)
- Farm Administrator access for deployment
- PowerShell execution enabled

## Technical Notes

- Handler uses `IsReusable = false` for thread-safety
- Error messages are sanitized (no stack traces exposed to clients)
- Errors are logged via `System.Diagnostics.Debug` (visible in ULS logs)
- Solution deploys to WebApplication bin (not GAC) - no assembly signing required

## License

- **This project**: MIT License
- **iTextSharp 5.x**: LGPL (free for commercial use)
- **BouncyCastle**: MIT License
