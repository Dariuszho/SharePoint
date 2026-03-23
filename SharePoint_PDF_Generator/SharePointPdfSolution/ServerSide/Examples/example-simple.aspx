<%@ Page Language="C#" MasterPageFile="~masterurl/default.master"
    Inherits="Microsoft.SharePoint.WebPartPages.WebPartPage,Microsoft.SharePoint,Version=16.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c"
    %>
    <%@ Register TagPrefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls"
        Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>

        <asp:Content ContentPlaceHolderID="PlaceHolderMain" runat="server">

            <style>
                .form-container {
                    max-width: 600px;
                    margin: 20px auto;
                    padding: 20px;
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    background: #f9f9f9;
                }

                .form-group {
                    margin-bottom: 15px;
                }

                .form-group label {
                    display: block;
                    margin-bottom: 5px;
                    font-weight: bold;
                }

                .form-group input,
                .form-group textarea {
                    width: 100%;
                    padding: 8px;
                    border: 1px solid #ccc;
                    border-radius: 4px;
                    box-sizing: border-box;
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

                .rtl-input {
                    direction: rtl;
                    text-align: right;
                }
            </style>

            <div id="statusMessage"></div>

            <div class="form-container">
                <h2>Simple PDF Generator (Hebrew/RTL Support)</h2>
                <p>Fill out the form below. Supports Hebrew, Arabic, English and numbers mixed.</p>
                <p dir="rtl">מלא את הטופס למטה. תומך בעברית, ערבית, אנגלית ומספרים.</p>

                <div class="form-group">
                    <label for="pdfFileName">PDF File Name:</label>
                    <input type="text" id="pdfFileName" value="FormSubmission" />
                    <span style="color: #666;">.pdf</span>
                </div>
                <div class="form-group">
                    <label for="userName">Name / שם:</label>
                    <input type="text" id="userName" class="rtl-input" placeholder="לדוגמה: ישראל ישראלי" />
                </div>
                <div class="form-group">
                    <label for="userEmail">Email / דוא"ל:</label>
                    <input type="text" id="userEmail" placeholder="example@domain.com" />
                </div>
                <div class="form-group">
                    <label for="department">Department / מחלקה:</label>
                    <input type="text" id="department" class="rtl-input" placeholder="לדוגמה: מחלקת IT" />
                </div>
                <div class="form-group">
                    <label for="comments">Comments / הערות:</label>
                    <textarea id="comments" rows="4" class="rtl-input" placeholder="הערות נוספות..."></textarea>
                </div>
                <button type="button" class="btn" id="createPdfBtn" onclick="generateAndUploadPDF();">Generate & Save
                    PDF</button>
            </div>

            <script type="text/javascript">
                // Configuration
                var PDF_HANDLER_URL = '/_layouts/15/SharePointPdfSolution/PdfGenerator.ashx';
                var TARGET_LIBRARY = '/sites/test/Shared Documents/';
                var isProcessing = false;

                function showMessage(message, type) {
                    var div = document.getElementById('statusMessage');
                    var colors = { success: '#d4edda', error: '#f8d7da', info: '#d1ecf1' };
                    div.innerHTML = message;
                    div.style.backgroundColor = colors[type] || colors.info;
                    div.style.display = 'block';
                    if (type !== 'info') {
                        setTimeout(function () { div.style.display = 'none'; }, 5000);
                    }
                }

                function resetButton() {
                    var btn = document.getElementById('createPdfBtn');
                    btn.disabled = false;
                    btn.innerHTML = 'Generate & Save PDF';
                }

                function generateAndUploadPDF() {
                    if (isProcessing) return;

                    var userName = document.getElementById('userName').value;
                    var userEmail = document.getElementById('userEmail').value;
                    var department = document.getElementById('department').value;
                    var comments = document.getElementById('comments').value;

                    if (!userName || !userEmail || !department) {
                        showMessage('Please fill in all required fields / נא למלא את כל השדות', 'error');
                        return;
                    }

                    isProcessing = true;
                    var btn = document.getElementById('createPdfBtn');
                    btn.disabled = true;
                    btn.innerHTML = 'Processing...';

                    showMessage('Generating PDF... / מייצר PDF...', 'info');

                    // Prepare form data for server
                    var formData = {
                        formType: 'simple',
                        title: 'טופס הגשה / Form Submission',
                        userName: userName,
                        userEmail: userEmail,
                        department: department,
                        comments: comments,
                        outputMode: 'base64'
                    };

                    // Call server-side handler
                    fetch(PDF_HANDLER_URL, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json'
                        },
                        body: JSON.stringify(formData)
                    })
                        .then(function (response) { return response.json(); })
                        .then(function (result) {
                            if (result.error) {
                                throw new Error(result.error);
                            }

                            showMessage('Uploading to SharePoint... / מעלה לשרת...', 'info');

                            // Convert base64 to blob
                            var byteCharacters = atob(result.pdfBase64);
                            var byteNumbers = new Array(byteCharacters.length);
                            for (var i = 0; i < byteCharacters.length; i++) {
                                byteNumbers[i] = byteCharacters.charCodeAt(i);
                            }
                            var byteArray = new Uint8Array(byteNumbers);
                            var pdfBlob = new Blob([byteArray], { type: 'application/pdf' });

                            // Generate filename with date suffix (dd.MM.yyyy)
                            var userFileName = document.getElementById('pdfFileName').value.trim() || 'FormSubmission';
                            if (userFileName.toLowerCase().indexOf('.pdf') === -1) {
                                userFileName = userFileName + '.pdf';
                            }
                            var now = new Date();
                            var day = ('0' + now.getDate()).slice(-2);
                            var month = ('0' + (now.getMonth() + 1)).slice(-2);
                            var year = now.getFullYear();
                            var dateSuffix = day + '.' + month + '.' + year;
                            var fileName = userFileName.replace('.pdf', '_' + dateSuffix + '.pdf');

                            // Upload to SharePoint
                            return uploadToSharePoint(pdfBlob, fileName);
                        })
                        .then(function (uploadResult) {
                            if (uploadResult.success) {
                                showMessage('PDF saved successfully! / ה-PDF נשמר בהצלחה!', 'success');
                                // Clear form
                                document.getElementById('userName').value = '';
                                document.getElementById('userEmail').value = '';
                                document.getElementById('department').value = '';
                                document.getElementById('comments').value = '';
                                document.getElementById('pdfFileName').value = 'FormSubmission';
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
                            if (!response.ok) throw new Error('Upload failed: ' + response.statusText);
                            return response.json();
                        })
                        .then(function (data) {
                            return { success: true, fileUrl: data.d.ServerRelativeUrl };
                        })
                        .catch(function (error) {
                            return { success: false, message: error.message };
                        });
                }
            </script>

        </asp:Content>