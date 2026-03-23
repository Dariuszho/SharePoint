<%@ Page Language="C#" MasterPageFile="~masterurl/default.master"
    Inherits="Microsoft.SharePoint.WebPartPages.WebPartPage,Microsoft.SharePoint,Version=16.0.0.0,Culture=neutral,PublicKeyToken=71e9bce111e9429c"
    %>
    <%@ Register TagPrefix="SharePoint" Namespace="Microsoft.SharePoint.WebControls"
        Assembly="Microsoft.SharePoint, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" %>

        <asp:Content ContentPlaceHolderID="PlaceHolderMain" runat="server">

            <style>
                .form-container {
                    max-width: 700px;
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
                .form-group textarea,
                .form-group select {
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

                .file-list {
                    margin-top: 10px;
                    padding: 10px;
                    background: white;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                }

                .file-item {
                    padding: 5px;
                    margin: 5px 0;
                    background: #f0f0f0;
                    border-radius: 3px;
                }

                .file-item.image {
                    background: #e8f5e9;
                }

                .rtl-input {
                    direction: rtl;
                    text-align: right;
                }
            </style>

            <div id="statusMessage"></div>

            <div class="form-container">
                <h2>PDF Generator with Attachments</h2>
                <p>Fill out the form and attach files. Images will be embedded in the PDF.</p>
                <p dir="rtl">מלא את הטופס וצרף קבצים. תמונות יוטמעו ב-PDF.</p>

                <div class="form-group">
                    <label for="pdfFileName">PDF File Name:</label>
                    <input type="text" id="pdfFileName" value="RequestSummary" />
                    <span style="color: #666;">.pdf</span>
                </div>
                <div class="form-group">
                    <label for="requestTitle">Request Title / כותרת הבקשה:</label>
                    <input type="text" id="requestTitle" class="rtl-input" />
                </div>
                <div class="form-group">
                    <label for="requesterName">Requester Name / שם המבקש:</label>
                    <input type="text" id="requesterName" class="rtl-input" />
                </div>
                <div class="form-group">
                    <label for="priority">Priority / עדיפות:</label>
                    <select id="priority">
                        <option value="נמוכה / Low">נמוכה / Low</option>
                        <option value="בינונית / Medium">בינונית / Medium</option>
                        <option value="גבוהה / High">גבוהה / High</option>
                        <option value="קריטית / Critical">קריטית / Critical</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="description">Description / תיאור:</label>
                    <textarea id="description" rows="5" class="rtl-input"></textarea>
                </div>
                <div class="form-group">
                    <label for="fileAttachments">Attach Files / צרף קבצים:</label>
                    <input type="file" id="fileAttachments" multiple onchange="displayFileList();" />
                    <div id="fileList" class="file-list" style="display:none;"></div>
                </div>
                <button type="button" class="btn" id="createPdfBtn" onclick="generatePDFWithAttachments();">Generate PDF
                    & Upload</button>
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
                    btn.innerHTML = 'Generate PDF & Upload';
                }

                function isImageFile(fileName) {
                    var ext = fileName.toLowerCase().split('.').pop();
                    return ext === 'jpg' || ext === 'jpeg' || ext === 'png' || ext === 'gif';
                }

                function displayFileList() {
                    var fileInput = document.getElementById('fileAttachments');
                    var fileListDiv = document.getElementById('fileList');

                    if (fileInput.files.length > 0) {
                        var html = '<strong>Selected Files:</strong><br>';
                        for (var i = 0; i < fileInput.files.length; i++) {
                            var file = fileInput.files[i];
                            var isImage = isImageFile(file.name);
                            var cssClass = isImage ? 'image' : '';
                            var label = isImage ? ' (will embed in PDF)' : ' (will upload separately)';
                            html += '<div class="file-item ' + cssClass + '">' + file.name + ' (' + (file.size / 1024).toFixed(2) + ' KB)' + label + '</div>';
                        }
                        fileListDiv.innerHTML = html;
                        fileListDiv.style.display = 'block';
                    } else {
                        fileListDiv.style.display = 'none';
                    }
                }

                function readFileAsBase64(file) {
                    return new Promise(function (resolve, reject) {
                        var reader = new FileReader();
                        var fileName = file.name;
                        var fileType = file.type;
                        reader.onload = function (e) {
                            resolve({ name: fileName, type: fileType, data: e.target.result });
                        };
                        reader.onerror = function () { reject(new Error('Failed to read file: ' + fileName)); };
                        reader.readAsDataURL(file);
                    });
                }

                function generatePDFWithAttachments() {
                    if (isProcessing) return;

                    var requestTitle = document.getElementById('requestTitle').value;
                    var requesterName = document.getElementById('requesterName').value;
                    var priority = document.getElementById('priority').value;
                    var description = document.getElementById('description').value;

                    if (!requestTitle || !requesterName) {
                        showMessage('Please fill in required fields / נא למלא שדות חובה', 'error');
                        return;
                    }

                    isProcessing = true;
                    var btn = document.getElementById('createPdfBtn');
                    btn.disabled = true;
                    btn.innerHTML = 'Processing...';

                    showMessage('Processing attachments... / מעבד קבצים...', 'info');

                    var fileInput = document.getElementById('fileAttachments');
                    var files = fileInput.files;
                    var nonImageFiles = [];

                    // Process files - collect promises for image files
                    var processPromises = [];
                    for (var i = 0; i < files.length; i++) {
                        var file = files[i];
                        if (isImageFile(file.name)) {
                            processPromises.push(readFileAsBase64(file));
                        } else {
                            nonImageFiles.push(file);
                        }
                    }

                    Promise.all(processPromises)
                        .then(function (imageAttachments) {
                            showMessage('Generating PDF... / מייצר PDF...', 'info');

                            var formData = {
                                formType: 'request',
                                title: 'סיכום בקשה / Request Summary',
                                requestTitle: requestTitle,
                                requesterName: requesterName,
                                priority: priority,
                                description: description,
                                attachments: imageAttachments,
                                outputMode: 'base64'
                            };

                            return fetch(PDF_HANDLER_URL, {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                                body: JSON.stringify(formData)
                            });
                        })
                        .then(function (response) { return response.json(); })
                        .then(function (result) {
                            if (result.error) throw new Error(result.error);

                            showMessage('Uploading PDF... / מעלה PDF...', 'info');

                            var byteCharacters = atob(result.pdfBase64);
                            var byteNumbers = new Array(byteCharacters.length);
                            for (var i = 0; i < byteCharacters.length; i++) {
                                byteNumbers[i] = byteCharacters.charCodeAt(i);
                            }
                            var pdfBlob = new Blob([new Uint8Array(byteNumbers)], { type: 'application/pdf' });

                            var userFileName = document.getElementById('pdfFileName').value.trim() || 'RequestSummary';
                            if (userFileName.toLowerCase().indexOf('.pdf') === -1) userFileName += '.pdf';
                            var now = new Date();
                            var day = ('0' + now.getDate()).slice(-2);
                            var month = ('0' + (now.getMonth() + 1)).slice(-2);
                            var year = now.getFullYear();
                            var dateSuffix = day + '.' + month + '.' + year;
                            var fileName = userFileName.replace('.pdf', '_' + dateSuffix + '.pdf');

                            return uploadToSharePoint(pdfBlob, fileName).then(function (result) {
                                return { pdfResult: result, nonImageFiles: nonImageFiles };
                            });
                        })
                        .then(function (data) {
                            if (!data.pdfResult.success) throw new Error(data.pdfResult.message);

                            // Upload non-image files separately
                            if (data.nonImageFiles.length > 0) {
                                showMessage('Uploading attachments... / מעלה קבצים...', 'info');
                                return uploadNonImageFiles(data.nonImageFiles, 0);
                            }
                            return Promise.resolve();
                        })
                        .then(function () {
                            showMessage('All files uploaded successfully! / כל הקבצים הועלו בהצלחה!', 'success');
                            // Clear form
                            document.getElementById('requestTitle').value = '';
                            document.getElementById('requesterName').value = '';
                            document.getElementById('description').value = '';
                            document.getElementById('pdfFileName').value = 'RequestSummary';
                            document.getElementById('fileList').style.display = 'none';
                            document.getElementById('fileAttachments').value = '';
                            isProcessing = false;
                            resetButton();
                        })
                        .catch(function (error) {
                            showMessage('Error: ' + error.message, 'error');
                            isProcessing = false;
                            resetButton();
                        });
                }

                function uploadNonImageFiles(files, index) {
                    if (index >= files.length) return Promise.resolve();

                    var file = files[index];
                    var fileName = file.name.replace(/[~#%&*{}\\:<>?/|"]/g, '_');
                    fileName = fileName.replace(/(\.[^.]+)$/, '_' + new Date().getTime() + '$1');

                    return uploadToSharePoint(file, fileName).then(function () {
                        return uploadNonImageFiles(files, index + 1);
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