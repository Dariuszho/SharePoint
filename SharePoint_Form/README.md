# SharePoint HTML Form

## Overview
An HTML-based form designed to run natively on SharePoint 2016 and above, submitting responses directly to a SharePoint library/list.

## Key Requirements

- **SharePoint 2016+** compatibility — uses only REST API features available from SharePoint 2016 onward.
- **Direct submission to SharePoint library** — form data is sent straight to a SharePoint list/library using the SharePoint REST API.
- **Fully offline / self-contained** — no external JavaScript libraries, CDNs, or additional script files are needed. All code is embedded in a single `.aspx` file.
- **Same-site deployment** — the form must be hosted on the same SharePoint site it submits to. This ensures the request digest (security token) is obtained from the current site context, preventing cross-site authorization issues.

## Files

| File                             | Description                                                                                          |
| -------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `sharepoint_form_reference.aspx` | **Reference only — do not modify.** Original English template used as the base for localized copies. |
| `sharepoint_form_heb.aspx`       | Hebrew (RTL) version of the form, ready for deployment.                                              |

## Deployment

1. Upload the `.aspx` file to a document library or the SitePages library on your SharePoint site.
2. Edit the `CONFIG` object inside the script to set your `siteUrl` and `listName`.
3. Make sure the target list exists and has columns matching the form field `name` attributes (e.g., `Name`, `Email`, `Department`, `Comments`).
4. Navigate to the uploaded page in the browser to use the form.

## Configuration

Inside the `<script>` block of each form file:

```js
var CONFIG = {
    siteUrl: "http://your-sharepoint-site/",  // SharePoint site URL
    listName: "YourListName"                   // Target list name
};
```

## Adding New Form Fields

To add a new field, insert a new `form-group` block **before** the submit button (`<button type="submit">שלח</button>`) and **after** the last existing field's closing `</div>`.

Use this pattern:

```html
<div class="form-group">
    <label>שם השדה:</label>
    <input type="text" name="ColumnName" required>
</div>
```

### Important Notes

- The `name` attribute **must match** the internal column name in your SharePoint list (e.g., `name="Phone"` maps to a column called `Phone`).
- The script automatically collects all `input`, `textarea`, and `select` elements by their `name` — no JavaScript changes are needed when adding fields.
- Supported field types: `<input>` (text, email, number, date, etc.), `<textarea>`, and `<select>`.
- Add `required` to make a field mandatory before submission.
