<#
.DESCRIPTION
Config auto refresh and sync refresh with time interval on web part with PnP Module.
For use on classic list on SharePoint On-Prem 2013 / 2016 / 2019.
Those setting are under AJAX Options on webpart edit from GUI.
.NOTES
To use PnP on oldest SharePoint Environments need to use legacy SharePoint PnP Module
version 3.29.2101.0 which is more not deployed or supported by Microsoft.
You are using this cmdlet on your own risk.
#>

$ErrorActionPreference = 'Stop'

# Import Module
Import-Module -Name SharePointPnPPowerShellOnline -DisableNameChecking

# Connect to site
$site = Read-Host -Prompt "Insert the URL of Site Collection"
Connect-PnPOnline -Url $site -CurrentCredentials -WarningAction Ignore

# Insert List and get propierties of the list and web part
$list = Read-Host -Prompt "Insert List Name"
$listprop = Get-PnPList -Identity $list
$webpart = Get-PnPWebPart -ServerRelativePageUrl $listprop.DefaultViewUrl

# Insert values for refresh time, the autorefresh and autosync will marked as true by code.
# Time interval is in seconds. Usualy default setting are False. Insert number of seconds on Value if you wish to change.
Set-PnPWebPartProperty -ServerRelativePageUrl $listprop.DefaultViewUrl -Identity  $webpart.Id -Key AutoRefreshInterval -Value:120
Set-PnPWebPartProperty -ServerRelativePageUrl $listprop.DefaultViewUrl -Identity  $webpart.Id -Key AutoRefresh -Value:$true
Set-PnPWebPartProperty -ServerRelativePageUrl $listprop.DefaultViewUrl -Identity  $webpart.Id -Key AsyncRefresh -Value:$true

# Let's get the settings after change
Get-PnPWebPartProperty -ServerRelativePageUrl $listprop.DefaultViewUrl -Identity $webpart.Id | Where-Object { $_.Key -eq 'AutoRefreshInterval' -or $_.Key -eq 'AutoRefresh' -or $_.Key -eq 'AsyncRefresh' } 
