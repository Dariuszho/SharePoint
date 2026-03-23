# SharePoint PDF Generator

Server-side PDF generation solution for SharePoint 2016 on-premises (also compatible with 2013/2019).

## Purpose
Generate PDFs from SharePoint forms with full RTL/Hebrew/Arabic support. PDFs are automatically saved to SharePoint document libraries without print dialogs.

## Key Features
- Full Hebrew, Arabic, and RTL language support
- Mixed text (Hebrew + English + Numbers) displays correctly
- No print dialog - direct save to SharePoint library
- Image attachments embedded in PDF
- Free for commercial use (LGPL license)

## Architecture Flow
```
[Browser Form] → [POST JSON] → [C# Handler] → [PDF with RTL] → [Upload to SharePoint]
```

1. Client (ASPX page) collects form data
2. Client sends JSON POST to `/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx`
3. Server generates PDF using iTextSharp with proper RTL/Hebrew support
4. Server returns PDF as base64
5. Client converts to blob and uploads to SharePoint library via REST API

## Form Types Supported
- `simple` - Basic form with name, email, department, comments
- `document` - Structured content with sections, lists, tables
- `request` - Request forms with title, requester, priority, description
