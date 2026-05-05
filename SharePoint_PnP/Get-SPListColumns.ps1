<#
.NOTES
That script return columns paramaters from SharePoint List 
.EXAMPLE
First, dot-source the file to load the function
. .\Get-SPListColumns.ps1

Then call the function
Get-SPListColumns -SiteUrl "https://yoursite.sharepoint.com" -ListName "YourList"
#>

function Get-SPListColumns {
    param(
        [Parameter(Mandatory = $true)][string]$SiteUrl,
        [Parameter(Mandatory = $true)][string]$ListName
    )

    Connect-PnPOnline -Url $SiteUrl -CurrentCredentials

    $fields = Get-PnPField -List $ListName | Where-Object { -not $_.Hidden -and -not $_.FromBaseType } |
    Select-Object Title, InternalName, TypeAsString |
    Sort-Object Title

    $fields | Format-Table -AutoSize

    Disconnect-PnPOnline
}
