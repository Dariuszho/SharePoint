<#
.DESCRIPTION
Testing sending e-mail message within SharePoint On-Prem SiteCollection
It works within server PowerShell CTL / ISE
.NOTES
Required configured ahead Outgoing E-Mail Settings via Central Administration
.SYNOPSIS
Using legacy SPUtility Method
.LINK
https://learn.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ms470715(v=office.14)
https://learn.microsoft.com/en-us/previous-versions/office/developer/sharepoint-2010/ms462952(v=office.14)
#>

# Let's get vairables
$email = Read-Host "Insert Send TO email address"
$subject = Read-Host "Insert subject of email"
$body = Read-Host "Add content to email body"
$siteCollectionUrl = Read-Host "Insert site collection URL"

# Lets' open send email
$site = New-Object Microsoft.SharePoint.SPSite $siteCollectionUrl
$web = $site.OpenWeb()
[Microsoft.SharePoint.Utilities.SPUtility]::SendEmail($web, 0, 0, $email, $subject, $body)

# Closing the send 
$web.Dispose()
$site.Dispose()