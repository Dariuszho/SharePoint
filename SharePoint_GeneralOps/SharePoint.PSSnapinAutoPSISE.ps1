<#
.DESCRIPTION
Load SharePoint PSSnapin to PowerShell ISE by Default
.NOTES
This is optional and is configured per user
To config on SharePoint Servers themselfs
#>

# Open PS ISE and run following, take note of full path

#Check if the profile file exists already  
if (Test-Path $profile) {
    Write-Host -ForegroundColor Yellow "Profile file already exists at: $profile"
}
else {
    #Create the profile file
    New-Item -Type file -Path $profile -Force
    Write-Host -ForegroundColor Yellow "Profile file has been created!"
} 

# From notification take the directory and name of profile

# Example Start-Process notepad \Users\%username%\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1
Start-Process notepad <path>\<profile_name> 

# Add folowing line and save 
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

