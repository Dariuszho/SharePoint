# Technology Stack

## Server-Side
- C# (.NET Framework 4.5+, C# 5 compatible)
- ASP.NET HTTP Handler (`.ashx`)
- SharePoint 2016 on-premises (compatible with 2013/2019)

## Libraries
- iTextSharp 5.5.13.4 (PDF generation, LGPL license)
- BouncyCastle 1.8.9 (cryptography dependency for iTextSharp)
- System.Web.Script.Serialization (JSON parsing)

## Client-Side
- Vanilla JavaScript (no frameworks)
- SharePoint REST API for file uploads
- Fetch API for HTTP requests

## Build System
- PowerShell scripts for build automation
- .NET Framework C# compiler (`csc.exe`)
- Windows `makecab` for WSP packaging

## Common Commands

### Download Dependencies
```powershell
cd SharePointPdfSolution\ServerSide
.\DownloadDependencies.ps1
```

### Build WSP Package
```powershell
cd SharePointPdfSolution\ServerSide
.\CreateWSP.ps1
```

### Deploy to SharePoint
```powershell
Add-SPSolution -LiteralPath "C:\path\to\SharePointPdfSolution.wsp"
Install-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Force
```

### Update Existing Deployment
```powershell
Uninstall-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Confirm:$false
Start-Sleep -Seconds 10
Remove-SPSolution -Identity SharePointPdfSolution.wsp -Confirm:$false
.\CreateWSP.ps1
Add-SPSolution -LiteralPath ".\SharePointPdfSolution.wsp"
Install-SPSolution -Identity SharePointPdfSolution.wsp -WebApplication "http://your-sharepoint-site" -Force
```

### Test Installation
```
http://your-site/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx?test=1
```

## Font Requirements
Server must have one of these fonts installed for RTL support:
- Arial Unicode MS (`arialuni.ttf`)
- Arial (`arial.ttf`)
- David (`david.ttf`)
- Tahoma (`tahoma.ttf`)
