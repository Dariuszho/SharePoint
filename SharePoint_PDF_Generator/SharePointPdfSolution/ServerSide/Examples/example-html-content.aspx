<%@ Page Language="C#" MasterPageFile="~masterurl/default.master"
    Inherits="Microsoft.SharePoint.WebPartPages.WebPartPage,Microsoft.SharePoint,Version=16.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c"
    %>
    <%@ Register TagPrefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls"
        Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>

        <asp:Content ContentPlaceHolderID="PlaceHolderMain" runat="server">

            <style>
                .container {
                    max-width: 800px;
                    margin: 20px auto;
                    padding: 20px;
                }

                .content-preview {
                    border: 2px dashed #ccc;
                    padding: 20px;
                    margin: 20px 0;
                    background: white;
                }

                .btn {
                    padding: 10px 20px;
                    background: #0078d4;
                    color: white;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 14px;
                }

                .btn:hover {
                    background: #005a9e;
                }

                .btn:disabled {
                    background: #ccc;
                    cursor: not-allowed;
                }

                #statusMessage {
                    display: none;
                    padding: 10px;
                    margin: 10px 0;
                    border-radius: 4px;
                }

                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 15px 0;
                }

                table th,
                table td {
                    border: 1px solid #ddd;
                    padding: 8px;
                    text-align: right;
                }

                table th {
                    background: #f2f2f2;
                }
            </style>

            <div id="statusMessage"></div>

            <div class="container">
                <h2>Document to PDF Converter (Hebrew Support)</h2>
                <p>The content below will be converted to PDF and saved to SharePoint.</p>

                <div style="margin-bottom: 15px;">
                    <label for="pdfFileName" style="font-weight: bold;">PDF File Name:</label>
                    <input type="text" id="pdfFileName" value="SampleDocument"
                        style="padding: 8px; width: 300px; border: 1px solid #ccc; border-radius: 4px;" />
                    <span style="color: #666;">.pdf</span>
                </div>

                <button type="button" class="btn" id="createPdfBtn" onclick="convertAndUpload();">Convert to PDF &
                    Save</button>

                <div class="content-preview">
                    <h3>Preview - This content will be in the PDF:</h3>
                    <hr />

                    <h4>מבוא / Introduction</h4>
                    <p>This is a sample document demonstrating PDF generation with full Hebrew support.</p>
                    <p dir="rtl">זהו מסמך לדוגמה המדגים יצירת PDF עם תמיכה מלאה בעברית. מספר טלפון: 054-1234567</p>

                    <h4>תכונות / Features</h4>
                    <ul dir="rtl">
                        <li>תמיכה מלאה בעברית עם מספרים 123</li>
                        <li>שמירה ישירה לספריית SharePoint</li>
                        <li>ללא חלון הדפסה</li>
                    </ul>

                    <h4>טבלת נתונים / Data Table</h4>
                    <table dir="rtl">
                        <thead>
                            <tr>
                                <th>פריט</th>
                                <th>תיאור</th>
                                <th>סטטוס</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>פריט 1</td>
                                <td>תיאור ראשון עם מספר 100</td>
                                <td>הושלם</td>
                            </tr>
                            <tr>
                                <td>פריט 2</td>
                                <td>תיאור שני עם email@test.com</td>
                                <td>בתהליך</td>
                            </tr>
                            <tr>
                                <td>פריט 3</td>
                                <td>תיאור שלישי</td>
                                <td>ממתין</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <script type="text/javascript">
                var PDF_HANDLER_URL = '/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx';
                var TARGET_LIBRARY = '/sites/test/Shared Documents/';
                var isProcessing = false;

                function showMessage(message, type) {
                    var div = document.getElementById('statusMessage');
                    var colors = { success: '#d4edda', error: '#f8d7da', info: '#d1ecf1' };
                    div.innerHTML = message;
                    div.style.backgroundColor = colors[type] || colors.info;
                    div.style.display = 'block';
                    if (type !== 'info') setTimeout(function () { div.style.display = 'none'; }, 5000);
                }

                function resetButton() {
                    var btn = document.getElementById('createPdfBtn');
                    btn.disabled = false;
                    btn.innerHTML = 'Convert to PDF & Save';
                }

                function convertAndUpload() {
                    if (isProcessing) return;

                    isProcessing = true;
                    var btn = document.getElementById('createPdfBtn');
                    btn.disabled = true;
                    btn.innerHTML = 'Processing...';

                    showMessage('Generating PDF... / מייצר PDF...', 'info');

                    var formData = {
                        formType: 'document',
                        title: 'מסמך לדוגמה / Sample Document',
                        sections: [
                            {
                                title: 'מבוא / Introduction',
                                content: 'This is a sample document demonstrating PDF generation with full Hebrew support.\n\nזהו מסמך לדוגמה המדגים יצירת PDF עם תמיכה מלאה בעברית. מספר טלפון: 054-1234567'
                            },
                            {
                                title: 'תכונות / Features',
                                content: '• תמיכה מלאה בעברית עם מספרים 123\n• שמירה ישירה לספריית SharePoint\n• ללא חלון הדפסה'
                            }
                        ],
                        tableData: {
                            headers: ['פריט', 'תיאור', 'סטטוס'],
                            rows: [
                                ['פריט 1', 'תיאור ראשון עם מספר 100', 'הושלם'],
                                ['פריט 2', 'תיאור שני עם email@test.com', 'בתהליך'],
                                ['פריט 3', 'תיאור שלישי', 'ממתין']
                            ]
                        },
                        outputMode: 'base64'
                    };

                    fetch(PDF_HANDLER_URL, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                        body: JSON.stringify(formData)
                    })
                        .then(function (response) { return response.json(); })
                        .then(function (result) {
                            if (result.error) throw new Error(result.error);

                            showMessage('Uploading to SharePoint...', 'info');

                            var byteCharacters = atob(result.pdfBase64);
                            var byteNumbers = new Array(byteCharacters.length);
                            for (var i = 0; i < byteCharacters.length; i++) {
                                byteNumbers[i] = byteCharacters.charCodeAt(i);
                            }
                            var pdfBlob = new Blob([new Uint8Array(byteNumbers)], { type: 'application/pdf' });

                            var userFileName = document.getElementById('pdfFileName').value.trim() || 'SampleDocument';
                            if (userFileName.toLowerCase().indexOf('.pdf') === -1) userFileName += '.pdf';
                            var now = new Date();
                            var day = ('0' + now.getDate()).slice(-2);
                            var month = ('0' + (now.getMonth() + 1)).slice(-2);
                            var year = now.getFullYear();
                            var dateSuffix = day + '.' + month + '.' + year;
                            var fileName = userFileName.replace('.pdf', '_' + dateSuffix + '.pdf');

                            return uploadToSharePoint(pdfBlob, fileName);
                        })
                        .then(function (uploadResult) {
                            if (uploadResult.success) {
                                showMessage('PDF saved successfully! / ה-PDF נשמר בהצלחה!', 'success');
                            } else {
                                throw new Error(uploadResult.message);
                            }
                            isProcessing = false;
                            resetButton();
                        })
                        .catch(function (error) {
                            showMessage('Error: ' + error.message, 'error');
                            isProcessing = false;
                            resetButton();
                        });
                }

                function uploadToSharePoint(fileBlob, fileName) {
                    var webUrl = _spPageContextInfo.webAbsoluteUrl;
                    var uploadUrl = webUrl + "/_api/web/GetFolderByServerRelativeUrl('" + TARGET_LIBRARY + "')/Files/add(url='" + fileName + "',overwrite=true)";

                    return fetch(uploadUrl, {
                        method: 'POST',
                        headers: {
                            'Accept': 'application/json;odata=verbose',
                            'X-RequestDigest': document.getElementById('__REQUESTDIGEST').value
                        },
                        body: fileBlob
                    })
                        .then(function (response) {
                            if (!response.ok) throw new Error('Upload failed');
                            return response.json();
                        })
                        .then(function (data) { return { success: true }; })
                        .catch(function (error) { return { success: false, message: error.message }; });
                }
            </script>

        </asp:Content>