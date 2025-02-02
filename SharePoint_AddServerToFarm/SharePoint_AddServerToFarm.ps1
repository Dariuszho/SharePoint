<#
.DESCRIPTION
Add SharePoint Server to Existing farm
.NOTES
Change the variables within script to meet your requirements 
#>

Clear-Host

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Configuration Settings
$DatabaseServer = "<SQL_Server_Allias>"
$Prefix = "<On DB Name>"
$suffix = "<On DB Name>"
$ConfigDatabase = $Prefix + "_SharePointConfig_" + $suffix

<# passphrase must meets all of the following criteria:  
    1.is at least 8 characters; 
    2.contains at least three following four character groups: English uppercase characters (A through Z); 
    3.English lowercase characters (a thrz); 
    4.Numerals (0 through 9); 
    5.Non-alphabetic characters (such as !, $, #, %).#>
$Passphrase = Read-Host -Prompt "Insert Passphrase for SharePoint Farm" -AsSecureString 

<# MinRoles:
  WebFrontEnd (Front-end server role),
  Application (Application server role),
  DistributedCache (Distributed Cache server role),
  Search (Search server role),
  WebFrontEndWithDistributedCache (Front-end with Distributed Cache server role),
  ApplicationWithSearch (Application with Search server role),
  Custom (Custom server role),
  SingleServerFarm (Single-Server Farm server role)
#>

#Choose from list above
$ServerRole = "Custom" 
 
#Get the Farm Account Credentials
$SecurePassPhrase = (ConvertTo-SecureString $Passphrase -AsPlainText -force)

#Connecting the server to the farm
Start-Sleep 5 
Connect-SPConfigurationDatabase -DatabaseServer $DatabaseServer -DatabaseName $ConfigDatabase -PassPhrase $SecurePassPhrase -LocalServerRole $ServerRole
  
Write-Host "Installing SharePoint Resources..." -ForegroundColor Cyan
Initialize-SPResourceSecurity
  
Write-Host "Installing Farm Services ..." -ForegroundColor Cyan
Install-SPService
  
Write-Host "Installing SharePoint Features..." -ForegroundColor Cyan
Install-SPFeature -AllExistingFeatures
  
Write-Host "Installing Help..." -ForegroundColor Cyan
Install-SPHelpCollection -All 
  
Write-Host "Installing Application Content..." -ForegroundColor Cyan
Install-SPApplicationContent
   
Write-Host "Joined the Server to Farm Successfully!" -ForegroundColor Green