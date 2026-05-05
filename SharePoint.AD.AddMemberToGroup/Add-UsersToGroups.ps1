<#
.DESCRIPTION
    Reads user requests from a SharePoint 2016+ on-premises list and adds
    the specified users to Active Directory groups. Designed to run unattended
    via Windows Task Scheduler under a domain service account.
.NOTES
    Created By Dariusz. Version 2.2
#>    

# ── Configuration Variables ──────────────────────────────────────────────────
$SiteURL = "https://sharepoint.site"
$ListName = "List Name"
$LogFilePath = "Log Path"
$UserIDField = "Field of User ID"
$GroupsField = "Field of Group"
$StatusField = "ProcessingStatus"
$ProcessedValue = "Processed"

# ── Email Configuration (reserved for future activation) ─────────────────────
# $EmailFrom       = "SharePoint@your.domain"
# $SmtpServer      = "smtp server"
# $SuccessSubject  = "AD Group Addition - Success"
# $FailureSubject  = "AD Group Addition - Failed"
# $ITAdminEmail    = "spadmin@your.domain"

# ── Helper Functions ─────────────────────────────────────────────────────────

function Write-Log {
    <#
    .SYNOPSIS
        Appends a timestamped log entry to the log file.
    .PARAMETER Message
        The message text to log.
    .PARAMETER Level
        Severity level: INFO, WARN, or ERROR. Defaults to INFO.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    # Ensure the log directory and file exist
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path -Path $LogFilePath)) {
        New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
    }

    # Build the formatted log entry and append it
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFilePath -Value $entry
}

# ── Module Import and SharePoint Connection ──────────────────────────────────
try {
    Import-Module SharePointPnPPowerShellOnline -DisableNameChecking
    Import-Module ActiveDirectory

    Connect-PNPOnline -Url $SiteURL -CurrentCredentials -WarningAction Ignore

    Write-Log -Message "=== Processing run started ==="

    # ── Retrieve Unprocessed List Items via CAML Query ───────────────────────
    $camlQuery = "<View><Query><Where><Or><IsNull><FieldRef Name='ProcessingStatus' /></IsNull><Eq><FieldRef Name='ProcessingStatus' /><Value Type='Text'></Value></Eq></Or></Where></Query></View>"

    $items = Get-PnPListItem -List $ListName -Query $camlQuery -PageSize 500

    if (-not $items -or $items.Count -eq 0) {
        Write-Log -Message "No unprocessed items found. Exiting."
        exit 0
    }
}
catch {
    Write-Log -Message "Fatal error during initialization: $_" -Level ERROR
    exit 1
}

$processedCount = 0
$skippedCount = 0
$errorCount = 0

# ── Process Each List Item ───────────────────────────────────────────────────
foreach ($item in $items) {
    try {
        # Extract fields from the list item
        $UserID = $item.FieldValues[$UserIDField]
        $RawGroups = $item.FieldValues[$GroupsField]

        # GroupsField is a Lookup/User field — extract the LookupValue string (e.g. "SNIFIM\jira_Group")
        if ($RawGroups -is [Microsoft.SharePoint.Client.FieldUserValue]) {
            $RawGroups = $RawGroups.LookupValue
        }
        elseif ($RawGroups -is [array]) {
            # Multi-value lookup — join all LookupValues with comma
            $RawGroups = ($RawGroups | ForEach-Object { $_.LookupValue }) -join ','
        }
        $RequesterEmail = $item.FieldValues["Author"].Email  # For future email use

        # Log what we're processing
        Write-Log -Message "Processing item ID $($item.Id): UserID=$UserID, Groups=$RawGroups"

        # Look up AD user by SamAccountName
        $adUser = Get-ADUser -Filter "SamAccountName -eq '$UserID'"
        if (-not $adUser) {
            Write-Log -Message "AD user not found for UserID: $UserID" -Level WARN
            $skippedCount++
            continue
        }

        # Parse target groups: split on commas, trim whitespace, strip domain\ prefixes, remove empties
        $GroupNames = ($RawGroups -Split ',').Trim() -Replace '^.+\\', '' | Where-Object { $_ -ne '' }

        # ── Process Each Group ───────────────────────────────────────────
        foreach ($GroupName in $GroupNames) {
            try {
                Add-ADGroupMember -Identity $GroupName -Members $adUser
                Write-Log -Message "Added user $UserID to group $GroupName"

                # ── Email notification: success (reserved for future activation) ──
                # $UserDisplayName = $adUser.Name
                # $successBody = @"
                # <!DOCTYPE html>
                # <html>
                # <head><meta charset="UTF-8"></head>
                # Change on line bellow direction according to language dir="ltr" or dir="rtl"
                # <body dir="ltr" style="font-family: Arial, sans-serif; font-size: 14px;">
                #   <!-- Add message body here -->
                #   <p>User Name: $UserDisplayName</p>
                #   <p>Group: $GroupName</p>
                # </body>
                # </html>
                # "@
                # Send-MailMessage -From $EmailFrom -To $RequesterEmail `
                #     -Subject $SuccessSubject `
                #     -Body $successBody `
                #     -BodyAsHtml `
                #     -Encoding UTF8 `
                #     -SmtpServer $SmtpServer
            }
            catch {
                if ($_.Exception.Message -match "already a member") {
                    Write-Log -Message "User $UserID is already a member of group $GroupName"
                }
                else {
                    Write-Log -Message "Error adding user $UserID to group ${GroupName}: $_" -Level ERROR
                }
            }
        }

        # ── Mark Item as Processed ───────────────────────────────────────
        try {
            Set-PnPListItem -List $ListName -Identity $item.Id -Values @{ $StatusField = $ProcessedValue }
        }
        catch {
            Write-Log -Message "Error updating processing marker for item ID $($item.Id): $_" -Level ERROR
        }

        $processedCount++
    }
    catch {
        Write-Log -Message "Error processing item ID $($item.Id): $_" -Level ERROR

        # ── Email notification: failure (reserved for future activation) ──
        # Send-MailMessage -From $EmailFrom -To $ITAdminEmail `
        #     -Subject $FailureSubject `
        #     -Body "Error processing item ID $($item.Id) for UserID $UserID: $_" `
        #     -SmtpServer $SmtpServer

        $errorCount++
        continue
    }
}

# ── Run Completion Summary ───────────────────────────────────────────────────
Write-Log -Message "=== Processing run completed. Processed: $processedCount, Skipped: $skippedCount, Errors: $errorCount ==="
