<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Form Submission</title>
    <style>
        body {
            font-family: Arial;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
        }

        .form-group {
            margin-bottom: 15px;
        }

        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }

        input,
        textarea,
        select {
            width: 100%;
            padding: 8px;
            box-sizing: border-box;
        }

        button {
            background: #0078d4;
            color: white;
            padding: 10px 20px;
            border: none;
            cursor: pointer;
        }

        button:hover {
            background: #005a9e;
        }

        .success {
            color: green;
            display: none;
        }

        .error {
            color: red;
            display: none;
        }
    </style>
</head>

<body>
    <h1>Submission Form</h1>

    <form id="mainForm">
        <!-- EDIT FORM FIELDS HERE -->
        <div class="form-group">
            <label>Name:</label>
            <input type="text" name="Name" required>
        </div>

        <div class="form-group">
            <label>Email:</label>
            <input type="email" name="Email" required>
        </div>

        <div class="form-group">
            <label>Department:</label>
            <select name="Department">
                <option>IT</option>
                <option>HR</option>
                <option>Finance</option>
                <option>Operations</option>
            </select>
        </div>

        <div class="form-group">
            <label>Comments:</label>
            <textarea name="Comments" rows="4"></textarea>
        </div>

        <button type="submit">Submit</button>
    </form>

    <p class="success" id="successMsg">Form submitted successfully!</p>
    <p class="error" id="errorMsg">Submission failed. Please try again.</p>

    <script>
        // CONFIGURATION - EDIT THESE VALUES
        var CONFIG = {
            siteUrl: "http://teamsitet/sites/test/",  // SharePoint site URL
            listName: "Form",                         // List Name
            submitToExcel: false                      // true = Excel/CSV, false = SharePoint list
        };

        document.getElementById('mainForm').addEventListener('submit', function (e) {
            e.preventDefault();
            alert('Form submitted! Processing...');

            var formData = {};
            var inputs = this.querySelectorAll('input, textarea, select');
            inputs.forEach(function (input) {
                if (input.name) formData[input.name] = input.value;
            });

            if (CONFIG.submitToExcel) {
                submitToExcel(formData);
            } else {
                submitToSharePointList(formData);
            }
        });

        function submitToSharePointList(data) {
            // Get list metadata and security token
            var xhr1 = new XMLHttpRequest();
            xhr1.open('GET', CONFIG.siteUrl + "/_api/web/lists/getbytitle('" + CONFIG.listName + "')?$select=ListItemEntityTypeFullName", true);
            xhr1.setRequestHeader('Accept', 'application/json;odata=verbose');

            xhr1.onload = function () {
                if (xhr1.status === 200) {
                    var response = JSON.parse(xhr1.responseText);
                    var listItemType = response.d.ListItemEntityTypeFullName;
                    getTokenAndSend(data, listItemType);
                } else {
                    alert('List not found. Check list name: ' + CONFIG.listName);
                    showError();
                }
            };

            xhr1.onerror = function () {
                alert('Network error');
                showError();
            };

            xhr1.send();
        }

        function getTokenAndSend(data, listItemType) {
            var xhr2 = new XMLHttpRequest();
            xhr2.open('POST', CONFIG.siteUrl + '/_api/contextinfo', true);
            xhr2.setRequestHeader('Accept', 'application/json;odata=verbose');

            xhr2.onload = function () {
                if (xhr2.status === 200) {
                    var response = JSON.parse(xhr2.responseText);
                    var digest = response.d.GetContextWebInformation.FormDigestValue;
                    sendToList(data, digest, listItemType);
                } else {
                    alert('Could not get security token');
                    showError();
                }
            };

            xhr2.send();
        }

        function sendToList(data, digest, listItemType) {
            var itemData = {
                __metadata: { type: listItemType }
            };
            for (var key in data) {
                itemData[key] = data[key];
            }

            var xhr = new XMLHttpRequest();
            xhr.open('POST', CONFIG.siteUrl + "/_api/web/lists/getbytitle('" + CONFIG.listName + "')/items", true);
            xhr.setRequestHeader('Accept', 'application/json;odata=verbose');
            xhr.setRequestHeader('Content-Type', 'application/json;odata=verbose');
            xhr.setRequestHeader('X-RequestDigest', digest);

            xhr.onload = function () {
                if (xhr.status === 201) {
                    showSuccess();
                } else {
                    alert('Error: ' + xhr.responseText);
                    showError();
                }
            };

            xhr.onerror = function () {
                alert('Network error occurred');
                showError();
            };

            xhr.send(JSON.stringify(itemData));
        }

        function submitToExcel(data) {
            var csv = Object.keys(data).join(',') + '\n' + Object.values(data).map(function (v) {
                return '"' + v + '"';
            }).join(',');

            var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            var link = document.createElement('a');
            var url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', 'form_submission_' + new Date().getTime() + '.csv');
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);

            showSuccess();
        }

        function showSuccess() {
            document.getElementById('successMsg').style.display = 'block';
            document.getElementById('errorMsg').style.display = 'none';
            document.getElementById('mainForm').reset();
            setTimeout(function () {
                document.getElementById('successMsg').style.display = 'none';
            }, 3000);
        }

        function showError() {
            document.getElementById('errorMsg').style.display = 'block';
            document.getElementById('successMsg').style.display = 'none';
        }
    </script>
</body>

</html>