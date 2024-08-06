<#
.DESCRIPTION
This it will measure time that took to download file.
Usefull to check small word or excell files on SharePoint or any File Web Server
The test is for 10 times in loop for, change as you wish 
Also you can change the path to another as you want
.NOTES
Ensure you have right to download file and / or singed to web site  
#>

# Define the URL of the file to download
$url = Read-Host 'Insert Web URL to file: '

# Define the path where the file will be saved
$output = "C:\temp\download"

# Loop 10 times
for ($i = 1; $i -le 10; $i++) {
    Write-Output "Iteration $i"

    # Measure the time taken to download the file
    $startTime = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    $endTime = Get-Date

    # Calculate the duration in seconds
    $duration = ($endTime - $startTime).TotalSeconds

    # Output the duration
    Write-Output "Time taken to download the file: $duration seconds"

    # Delete the downloaded file
    Remove-Item -Path $output
}

Write-Host -ForegroundColor Green "Completed 10 iterations."
