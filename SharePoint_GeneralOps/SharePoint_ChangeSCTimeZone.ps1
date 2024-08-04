<#
.DESCRIPTION
Check and update Time Zone for Site Collections on SharePoint On-Premises
.NOTES
Time Zones you can find in file TimeZones or use third region to get them from local SP
There are three regions, the first one is checking existin time zone for Site Collection
The secondary change to choosed time zone for all Site Collections
Time Zones you can find in file 'TimeZones, or use third region to get them from local SP
If need only some Site Collections or invidual, can easly use without foreach on secondery region or insert list of sites from CSV/Text file
#>

#region Let's find which web sites don't have proper configuration on Time Zone

Clear-Host

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop

$Sites = (Get-SPSite -Limit All).URL

foreach ($Site in $Sites) {

    $web = Get-SPWeb -Identity $site 

    Write-Host $web.RegionalSettings.TimeZone.Description $web.Url -ForegroundColor Yellow

}

#endregion

#region Change Time Zone on all Site Collection

Clear-Host

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop

$TimeZoneID = Read-Host "Insert Time Zone ID in format digital number "

$Sites = (Get-SPSite -Limit All).URL

foreach ($Site in $Sites) {

    $web = Get-SPWeb -Identity $site

    if ($web.RegionalSettings.TimeZone.ID -ne $TimeZoneID) {

        Write-Host "Updating Time Zone for $Site" -ForegroundColor Cyan

        $web.RegionalSettings.TimeZone.ID = $TimeZoneID

        $web.Update()

        $web.Dispose()
 
    }

}

#endregion

#region Let's get Time Zones form SharePoint

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop

$SiteURL = Read-Host "Insert Site Collection URL "

$Web = Get-SPWeb -Identity $SiteURL

$Web.RegionalSettings.TimeZones | Select-Object ID, Description

#endregion
