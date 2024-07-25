<#
 
.DESCRIPTION
 This script would help you to backup all SharePoint WSP Solutions installed on your farm with logging and versioning history capabilities.
 For more details about the script features and how this script works, Please check https://spgeeks.devoworx.com/backup-all-wsp-sharepoint-powershell
 
#> 
Param()

function Backup-WSPSolutions() {
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
    Try { 
        #Backup all wps solutions
        $WSPCount = (Get-SPSolution).Count
        #Check if there are deployed solutions
        if ($WSPCount -eq 0) {
            Write-Output "There are no solutions in the solution store"
        }
        else {
            #Create a new folder with the current date and time
            $RootFolderPath = "C:\Temp\WSPSolutions_Backup"
            Write-Output "Backup all WPS SharePoint Solutions ($WSPCount) to $RootFolderPath" 
            Get-SPSolution | Select-Object Name, Deployed | Format-Table
            Write-Output "--------------------------------------------------------------"
            $reply = Read-Host -Prompt "Are you sure you need to backup all wsp solutions to $RootFolderPath ?[y/n]" 
                
            if ( $reply -match "[yY]" ) { 
                  
                #create latest backup folder
                $RootFolderPathLatest = "$RootFolderPath\01-Latest-WSPBackup"
                if (-not(Test-path $RootFolderPathLatest)) {
                    New-Item -ItemType Directory -Path $RootFolderPathLatest
                }
                    
                # create log file
                $LogFilePath = "$RootFolderPath\Log.txt"
                if (-not(Test-path $LogFilePath -PathType Leaf)) {
                    New-Item -ItemType File -Path $LogFilePath
                }
                    
                foreach ($solution in Get-SPSolution) {
                    $WSPname = $Solution.Name
                    $WSPFolderPath = "$RootFolderPath\$WSPname\$((Get-Date).ToString('yyyy-MM-dd'))"
                    New-Item -ItemType Directory -Path $WSPFolderPath
                    #save versioning
                    $solution.SolutionFile.SaveAs("$WSPFolderPath\$WSPname")                              
                    $solution.SolutionFile.SaveAs("$RootFolderPathLatest\$WSPname")
                      
                }
                    
                Write-Output "All WPS SharePoint Solutions($WSPCount) have been backuped to $RootFolderPath"
                $userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                Add-Content $LogFilePath "`nWSP Count: $WSPCount`t | Done by: $userName`t | Backup date: $((Get-Date))"
                # Open the beackup folder
                Invoke-Item -Path $RootFolderPath
            }
        }
    }
    Catch {
        Write-Output $_.Exception.Message
        break
    }
}


#run the bacpup all SharePoint WSP solutions and build the version history for each WSP
Backup-WSPSolutions