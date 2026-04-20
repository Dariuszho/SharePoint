<!DOCTYPE html>
<html dir="rtl" lang="he">

<head>
    <meta charset="UTF-8">
    <title>טופס הגשה</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 40px 20px;
            direction: rtl;
            min-height: 100vh;
            background: linear-gradient(135deg, #e0ecff 0%, #b3d1ff 40%, #7ab8ff 100%);
        }

        h1 {
            color: #1a1a2e;
            margin-bottom: 25px;
        }

        #mainForm {
            max-width: 600px;
            margin: 0 auto;
            background: #ffffff;
            padding: 35px;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
        }

        .form-group {
            margin-bottom: 18px;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-weight: bold;
            color: #333;
        }

        input,
        textarea,
        select {
            width: 100%;
            padding: 10px 14px;
            box-sizing: border-box;
            border: 1px solid #ccc;
            border-radius: 10px;
            font-size: 14px;
            transition: border-color 0.2s;
        }

        input:focus,
        textarea:focus,
        select:focus {
            outline: none;
            border-color: #5c6bc0;
            box-shadow: 0 0 0 3px rgba(92, 107, 192, 0.15);
        }

        button {
            background: #4a148c;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
            transition: background 0.2s;
            margin-top: 10px;
        }

        button:hover {
            background: #6a1b9a;
        }

        .success {
            color: green;
            display: none;
            text-align: center;
            max-width: 600px;
            margin: 15px auto;
        }

        .error {
            color: red;
            display: none;
            text-align: center;
            max-width: 600px;
            margin: 15px auto;
        }
    </style>
</head>

<body>
    <form id="mainForm">
        <h1>טופס הגשה</h1>
        <!-- ערוך שדות טופס כאן -->
        <div class="form-group">
            <label>שם:</label>
            <input type="text" name="Name" required>
        </div>

        <div class="form-group">
            <label>דוא"ל:</label>
            <input type="email" name="Email" required>
        </div>

        <div class="form-group">
            <label>מחלקה:</label>
            <select name="Department">
                <option>מערכות מידע</option>
                <option>משאבי אנוש</option>
                <option>כספים</option>
                <option>תפעול</option>
            </select>
        </div>

        <div class="form-group">
            <label>הערות:</label>
            <textarea name="Comments" rows="4"></textarea>
        </div>

        <button type="submit">שלח</button>
    </form>

    <p class="success" id="successMsg">הטופס נשלח בהצלחה!</p>
    <p class="error" id="errorMsg">השליחה נכשלה. אנא נסה שנית.</p>

    <script>
        // הגדרות - ערוך ערכים אלה
        var CONFIG = {
            siteUrl: "http://sharepoint.site",  // כתובת אתר SharePoint
            listName: "Form Name"                          // שם הרשימה
        };

        document.getElementById('mainForm').addEventListener('submit', function (e) {
            e.preventDefault();
            alert('הטופס נשלח! מעבד...');

            var formData = {};
            var inputs = this.querySelectorAll('input, textarea, select');
            inputs.forEach(function (input) {
                if (input.name) formData[input.name] = input.value;
            });

            submitToSharePointList(formData);
        });

        function submitToSharePointList(data) {
            var xhr1 = new XMLHttpRequest();
            xhr1.open('GET', CONFIG.siteUrl + "/_api/web/lists/getbytitle('" + CONFIG.listName + "')?$select=ListItemEntityTypeFullName", true);
            xhr1.setRequestHeader('Accept', 'application/json;odata=verbose');

            xhr1.onload = function () {
                if (xhr1.status === 200) {
                    var response = JSON.parse(xhr1.responseText);
                    var listItemType = response.d.ListItemEntityTypeFullName;
                    getTokenAndSend(data, listItemType);
                } else {
                    alert('הרשימה לא נמצאה. בדוק את שם הרשימה: ' + CONFIG.listName);
                    showError();
                }
            };

            xhr1.onerror = function () {
                alert('שגיאת רשת');
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
                    alert('לא ניתן לקבל אסימון אבטחה');
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
                    alert('שגיאה: ' + xhr.responseText);
                    showError();
                }
            };

            xhr.onerror = function () {
                alert('אירעה שגיאת רשת');
                showError();
            };

            xhr.send(JSON.stringify(itemData));
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