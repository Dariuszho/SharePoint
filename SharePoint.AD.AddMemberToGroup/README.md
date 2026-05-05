# SharePoint AD Group Automation

PowerShell scripts for automating Active Directory group membership based on requests submitted through a SharePoint list. Designed to run unattended via Windows Task Scheduler.

---

## Scripts

### `Add-UsersToGroups.ps1`
Reads unprocessed items from a SharePoint list using a **CAML query** (filters by a `ProcessingStatus` field) and adds the specified users to AD groups. Marks each item as `Processed` in the list after handling.

### `Add-UsersToGroups-NoCAML.ps1`
Same logic as above, but uses a **local tracking file** (`processed_ids.txt`) instead of a CAML query to identify unprocessed items. Useful when the SharePoint list doesn't have a status column or when write-back to the list isn't desired.

### `Get-SPListColumns.ps1`
A utility function that connects to a SharePoint site and returns all non-hidden, non-base-type columns from a given list — useful for discovering internal field names needed to configure the scripts above.

**Usage:**
```powershell
. .\Get-SPListColumns.ps1
Get-SPListColumns -SiteUrl "https://yoursite.sharepoint.com" -ListName "YourList"
```

---

## Prerequisites

- **PnP PowerShell** (`SharePointPnPPowerShellOnline` module)
- **ActiveDirectory** PowerShell module (RSAT)
- A domain service account with permissions to:
  - Read the SharePoint list
  - Add members to the target AD groups

---

## Configuration

Edit the variables at the top of each script before running:

| Variable | Description |
|---|---|
| `$SiteURL` | URL of the SharePoint site |
| `$ListName` | Name of the SharePoint list |
| `$LogFilePath` | Path for the log file |
| `$UserIDField` | Internal name of the field containing the AD `SamAccountName` |
| `$GroupsField` | Internal name of the field containing target AD group names |
| `$StatusField` | *(CAML version only)* Field used to mark items as processed |
| `$ProcessedIDsFile` | *(NoCAML version only)* Path to the local tracking file |

> Use `Get-SPListColumns.ps1` to find the correct internal field names.

---

## Logging

Both scripts write timestamped log entries (`INFO`, `WARN`, `ERROR`) to the configured log file. A summary line is written at the end of each run showing processed, skipped, and error counts.

---

## Notes

- Email notifications are implemented in the code but commented out — configure and uncomment to activate.
- Both scripts handle multi-value group fields and strip domain prefixes (e.g., `DOMAIN\group_name` → `group_name`).
- If a user is already a member of a group, it is logged as informational rather than an error.
