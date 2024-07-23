<#
// Script for disable offline sync with onedrive on mysite / personal site #
// Tested and confirmed on enviroments
// - SharePoint 2019 On-Prem 
// - SharePoint Subscription Edition On-Prem
// To run directly from back-end server with applications MiniRole
// Can be run from PowerShell ISE as Admin
// The second region for invidual user can be configured with CSV file and with foreach if needed
#>

#region  // All Personal Sites //
              
Add-PSSnapin 'Microsoft.SharePoint.PowerShell' -ErrorAction Stop

$sites = Get-SPSite https://<Web_Application_URL>/personal/* -Limit All

foreach ($site in $sites) {
    $siteweb = $site.OpenWeb()
    $siteweb.ExcludeFromOfflineClient = $true
    $siteweb.Update()
}

#endregion 

#region  // Invidual User Personal Site //

Add-PSSnapin 'Microsoft.SharePoint.PowerShell' -ErrorAction Stop

#Use LoginName
$UserName = "<sAMAccountName>"
$usersite = get-spsite https://<Web_Application_URL>/personal/$UserName
$userweb = $usersite.OpenWeb()
$userweb.ExcludeFromOfflineClient = $true
$userweb.Update()

#endregion