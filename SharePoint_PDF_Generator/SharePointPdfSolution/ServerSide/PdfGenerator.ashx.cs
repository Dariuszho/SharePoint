using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using iTextSharp.text;
using iTextSharp.text.pdf;

namespace SharePointPdfSolution
{
    public class PdfGenerator : IHttpHandler
    {
        private static readonly string[] FontPaths = new string[]
        {
            @"C:\Windows\Fonts\arialuni.ttf",
            @"C:\Windows\Fonts\arial.ttf",
            @"C:\Windows\Fonts\david.ttf",
            @"C:\Windows\Fonts\tahoma.ttf"
        };

        public bool IsReusable { get { return false; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.AddHeader("Cache-Control", "no-cache");

            try
            {
                if (context.Request.QueryString["test"] == "1")
                {
                    WriteJsonResponse(context, new { status = "ok", message = "PDF Generator is running" });
                    return;
                }

                if (context.Request.HttpMethod != "POST")
                {
                    context.Response.StatusCode = 405;
                    WriteJsonResponse(context, new { error = "Method not allowed. Use POST." });
                    return;
                }

                string requestBody;
                using (var reader = new StreamReader(context.Request.InputStream, Encoding.UTF8))
                {
                    requestBody = reader.ReadToEnd();
                }

                if (string.IsNullOrEmpty(requestBody))
                {
                    context.Response.StatusCode = 400;
                    WriteJsonResponse(context, new { error = "Request body is empty" });
                    return;
                }

                var serializer = new JavaScriptSerializer();
                var formData = serializer.Deserialize<Dictionary<string, object>>(requestBody);

                byte[] pdfBytes = GeneratePdf(formData);

                string outputMode = GetStringValue(formData, "outputMode", "base64");
                
                if (outputMode == "download")
                {
                    string fileName = GetStringValue(formData, "fileName", "document.pdf");
                    context.Response.ContentType = "application/pdf";
                    context.Response.AddHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
                    context.Response.BinaryWrite(pdfBytes);
                }
                else
                {
                    string base64Pdf = Convert.ToBase64String(pdfBytes);
                    WriteJsonResponse(context, new { 
                        success = true, 
                        pdfBase64 = base64Pdf,
                        size = pdfBytes.Length
                    });
                }
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                WriteJsonResponse(context, new { 
                    error = "An error occurred while generating the PDF. Please try again."
                });
                // Log the actual error for debugging (check ULS logs)
                System.Diagnostics.Debug.WriteLine("PDF Generator Error: " + ex.Message + Environment.NewLine + ex.StackTrace);
            }
        }

        private byte[] GeneratePdf(Dictionary<string, object> formData)
        {
            using (var memoryStream = new MemoryStream())
            {
                Document document = new Document(PageSize.A4, 40, 40, 40, 40);
                PdfWriter writer = PdfWriter.GetInstance(document, memoryStream);
                
                document.Open();

                BaseFont baseFont = GetUnicodeFont();
                
                string formType = GetStringValue(formData, "formType", "simple");
                string title = GetStringValue(formData, "title", "Form Submission");

                // Title - centered
                AddRtlParagraph(document, title, 20, Font.BOLD, Element.ALIGN_CENTER, 0, 20, baseFont);

                // Line
                AddHorizontalLine(document);

                if (formType == "simple")
                {
                    AddSimpleFormFields(document, formData, baseFont);
                }
                else if (formType == "document")
                {
                    AddDocumentContent(document, formData, baseFont);
                }
                else if (formType == "request")
                {
                    AddRequestFormFields(document, formData, baseFont);
                }

                if (formData.ContainsKey("attachments"))
                {
                    AddAttachments(document, formData, baseFont);
                }

                // Footer
                Font footerFont = new Font(baseFont, 9, Font.NORMAL, BaseColor.GRAY);
                Paragraph footer = new Paragraph("Generated: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"), footerFont);
                footer.SpacingBefore = 30;
                document.Add(footer);

                document.Close();
                return memoryStream.ToArray();
            }
        }

        private void AddRtlParagraph(Document document, string text, float fontSize, int fontStyle, int alignment, float indentation, float spacingAfter, BaseFont baseFont)
        {
            Font font = new Font(baseFont, fontSize, fontStyle, BaseColor.BLACK);
            
            PdfPTable table = new PdfPTable(1);
            table.WidthPercentage = 100;
            table.SpacingAfter = spacingAfter;
            
            PdfPCell cell = new PdfPCell();
            cell.Border = Rectangle.NO_BORDER;
            cell.RunDirection = PdfWriter.RUN_DIRECTION_RTL;
            cell.HorizontalAlignment = alignment;
            cell.PaddingLeft = indentation;
            
            Phrase phrase = new Phrase(text, font);
            cell.AddElement(phrase);
            
            table.AddCell(cell);
            document.Add(table);
        }

        private void AddHorizontalLine(Document document)
        {
            PdfPTable lineTable = new PdfPTable(1);
            lineTable.WidthPercentage = 100;
            lineTable.SpacingBefore = 5;
            lineTable.SpacingAfter = 15;
            PdfPCell lineCell = new PdfPCell();
            lineCell.BorderWidthBottom = 1;
            lineCell.BorderWidthTop = 0;
            lineCell.BorderWidthLeft = 0;
            lineCell.BorderWidthRight = 0;
            lineCell.BorderColorBottom = BaseColor.GRAY;
            lineCell.FixedHeight = 1;
            lineTable.AddCell(lineCell);
            document.Add(lineTable);
        }

        private BaseFont GetUnicodeFont()
        {
            foreach (string fontPath in FontPaths)
            {
                if (File.Exists(fontPath))
                {
                    try
                    {
                        return BaseFont.CreateFont(fontPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Font loading failed for " + fontPath + ": " + ex.Message);
                    }
                }
            }
            return BaseFont.CreateFont(BaseFont.HELVETICA, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
        }

        private void AddSimpleFormFields(Document document, Dictionary<string, object> formData, BaseFont baseFont)
        {
            AddFieldWithLabel(document, "Name / שם:", GetStringValue(formData, "userName", ""), baseFont);
            AddFieldWithLabel(document, "Email / דוא\"ל:", GetStringValue(formData, "userEmail", ""), baseFont);
            AddFieldWithLabel(document, "Department / מחלקה:", GetStringValue(formData, "department", ""), baseFont);
            
            string comments = GetStringValue(formData, "comments", "");
            if (!string.IsNullOrEmpty(comments))
            {
                AddFieldWithLabel(document, "Comments / הערות:", "", baseFont);
                AddRtlParagraph(document, comments, 11, Font.NORMAL, Element.ALIGN_RIGHT, 20, 10, baseFont);
            }
        }

        private void AddDocumentContent(Document document, Dictionary<string, object> formData, BaseFont baseFont)
        {
            Font valueFont = new Font(baseFont, 11, Font.NORMAL, BaseColor.BLACK);

            // Date
            Paragraph datePara = new Paragraph("Date: " + DateTime.Now.ToString("yyyy-MM-dd"), valueFont);
            datePara.SpacingAfter = 15;
            document.Add(datePara);

            if (formData.ContainsKey("sections"))
            {
                var sectionsObj = formData["sections"];
                System.Collections.IEnumerable sections = sectionsObj as System.Collections.ArrayList;
                if (sections == null)
                {
                    sections = sectionsObj as object[];
                }
                if (sections != null)
                {
                    foreach (var sectionObj in sections)
                    {
                        var section = sectionObj as Dictionary<string, object>;
                        if (section != null)
                        {
                            string sectionTitle = GetStringValue(section, "title", "");
                            string sectionContent = GetStringValue(section, "content", "");

                            if (!string.IsNullOrEmpty(sectionTitle))
                            {
                                AddRtlParagraph(document, sectionTitle, 14, Font.BOLD, Element.ALIGN_RIGHT, 0, 5, baseFont);
                            }

                            if (!string.IsNullOrEmpty(sectionContent))
                            {
                                AddRtlParagraph(document, sectionContent, 11, Font.NORMAL, Element.ALIGN_RIGHT, 0, 15, baseFont);
                            }
                        }
                    }
                }
            }

            if (formData.ContainsKey("tableData"))
            {
                AddTableData(document, formData, baseFont);
            }
        }

        private void AddRequestFormFields(Document document, Dictionary<string, object> formData, BaseFont baseFont)
        {
            AddFieldWithLabel(document, "Request Title / כותרת:", GetStringValue(formData, "requestTitle", ""), baseFont);
            AddFieldWithLabel(document, "Requester / מבקש:", GetStringValue(formData, "requesterName", ""), baseFont);
            AddFieldWithLabel(document, "Priority / עדיפות:", GetStringValue(formData, "priority", ""), baseFont);

            string description = GetStringValue(formData, "description", "");
            if (!string.IsNullOrEmpty(description))
            {
                AddFieldWithLabel(document, "Description / תיאור:", "", baseFont);
                AddRtlParagraph(document, description, 11, Font.NORMAL, Element.ALIGN_RIGHT, 20, 10, baseFont);
            }
        }

        private void AddFieldWithLabel(Document document, string label, string value, BaseFont baseFont)
        {
            Font labelFont = new Font(baseFont, 11, Font.BOLD, BaseColor.BLACK);
            Font valueFont = new Font(baseFont, 11, Font.NORMAL, BaseColor.BLACK);

            PdfPTable table = new PdfPTable(2);
            table.WidthPercentage = 100;
            table.SetWidths(new float[] { 65, 35 });
            table.SpacingAfter = 8;

            // Value cell (left side visually, but first in RTL)
            PdfPCell valueCell = new PdfPCell();
            valueCell.Border = Rectangle.NO_BORDER;
            valueCell.RunDirection = PdfWriter.RUN_DIRECTION_RTL;
            valueCell.HorizontalAlignment = Element.ALIGN_RIGHT;
            valueCell.AddElement(new Phrase(value, valueFont));
            table.AddCell(valueCell);

            // Label cell (right side visually)
            PdfPCell labelCell = new PdfPCell();
            labelCell.Border = Rectangle.NO_BORDER;
            labelCell.RunDirection = PdfWriter.RUN_DIRECTION_RTL;
            labelCell.HorizontalAlignment = Element.ALIGN_RIGHT;
            labelCell.AddElement(new Phrase(label, labelFont));
            table.AddCell(labelCell);

            document.Add(table);
        }

        private void AddTableData(Document document, Dictionary<string, object> formData, BaseFont baseFont)
        {
            var tableData = formData["tableData"] as Dictionary<string, object>;
            if (tableData == null) return;

            var headersObj = tableData["headers"];
            var rowsObj = tableData["rows"];
            
            System.Collections.IList headers = headersObj as System.Collections.ArrayList;
            if (headers == null)
            {
                headers = headersObj as object[];
            }
            System.Collections.IEnumerable rows = rowsObj as System.Collections.ArrayList;
            if (rows == null)
            {
                rows = rowsObj as object[];
            }

            if (headers == null || rows == null) return;

            Font headerFont = new Font(baseFont, 11, Font.BOLD, BaseColor.BLACK);
            Font cellFont = new Font(baseFont, 10, Font.NORMAL, BaseColor.BLACK);

            PdfPTable table = new PdfPTable(headers.Count);
            table.WidthPercentage = 100;
            table.SpacingBefore = 15;
            table.SpacingAfter = 15;
            table.RunDirection = PdfWriter.RUN_DIRECTION_RTL;

            foreach (var header in headers)
            {
                PdfPCell cell = new PdfPCell(new Phrase(header.ToString(), headerFont));
                cell.BackgroundColor = new BaseColor(230, 230, 230);
                cell.Padding = 8;
                cell.HorizontalAlignment = Element.ALIGN_CENTER;
                cell.RunDirection = PdfWriter.RUN_DIRECTION_RTL;
                table.AddCell(cell);
            }

            foreach (var rowObj in rows)
            {
                System.Collections.IEnumerable row = rowObj as System.Collections.ArrayList;
                if (row == null)
                {
                    row = rowObj as object[];
                }
                if (row != null)
                {
                    foreach (var cellValue in row)
                    {
                        string cellText = cellValue != null ? cellValue.ToString() : "";
                        PdfPCell cell = new PdfPCell(new Phrase(cellText, cellFont));
                        cell.Padding = 6;
                        cell.HorizontalAlignment = Element.ALIGN_CENTER;
                        cell.RunDirection = PdfWriter.RUN_DIRECTION_RTL;
                        table.AddCell(cell);
                    }
                }
            }

            document.Add(table);
        }

        private void AddAttachments(Document document, Dictionary<string, object> formData, BaseFont baseFont)
        {
            var attachmentsObj = formData["attachments"];
            System.Collections.IList attachments = attachmentsObj as System.Collections.ArrayList;
            if (attachments == null)
            {
                attachments = attachmentsObj as object[];
            }
            if (attachments == null || attachments.Count == 0) return;

            AddRtlParagraph(document, "Attachments / קבצים מצורפים:", 14, Font.BOLD, Element.ALIGN_RIGHT, 0, 10, baseFont);

            foreach (var attachObj in attachments)
            {
                var attachment = attachObj as Dictionary<string, object>;
                if (attachment == null) continue;

                string fileName = GetStringValue(attachment, "name", "unknown");
                string fileType = GetStringValue(attachment, "type", "");
                string base64Data = GetStringValue(attachment, "data", "");

                AddRtlParagraph(document, "• " + fileName, 11, Font.NORMAL, Element.ALIGN_RIGHT, 10, 5, baseFont);

                if (IsImageType(fileType) && !string.IsNullOrEmpty(base64Data))
                {
                    try
                    {
                        if (base64Data.Contains(","))
                        {
                            base64Data = base64Data.Substring(base64Data.IndexOf(",") + 1);
                        }

                        byte[] imageBytes = Convert.FromBase64String(base64Data);
                        Image image = Image.GetInstance(imageBytes);
                        
                        float maxWidth = document.PageSize.Width - 100;
                        float maxHeight = 300;
                        
                        if (image.Width > maxWidth || image.Height > maxHeight)
                        {
                            image.ScaleToFit(maxWidth, maxHeight);
                        }

                        image.SpacingBefore = 10;
                        image.SpacingAfter = 10;
                        image.Alignment = Element.ALIGN_CENTER;
                        
                        document.Add(image);
                    }
                    catch (Exception ex)
                    {
                        AddRtlParagraph(document, "[Error loading image]", 10, Font.NORMAL, Element.ALIGN_RIGHT, 20, 5, baseFont);
                        System.Diagnostics.Debug.WriteLine("Image loading error for " + fileName + ": " + ex.Message);
                    }
                }
            }
        }

        private bool IsImageType(string mimeType)
        {
            if (string.IsNullOrEmpty(mimeType)) return false;
            return mimeType.ToLower().StartsWith("image/");
        }

        private string GetStringValue(Dictionary<string, object> dict, string key, string defaultValue)
        {
            if (dict == null || !dict.ContainsKey(key)) return defaultValue;
            var value = dict[key];
            if (value == null) return defaultValue;
            return value.ToString();
        }

        private void WriteJsonResponse(HttpContext context, object data)
        {
            var serializer = new JavaScriptSerializer();
            context.Response.Write(serializer.Serialize(data));
        }
    }
}