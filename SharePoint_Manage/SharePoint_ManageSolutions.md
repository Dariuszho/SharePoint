_Brief review on solution managment_

* **Add the Soluution to SharePoint**
#### Open SharePoint Managment Shell as Admin
#### Add the Solution with command 

```powershell
Add-SPSolution -LiteralPath "<path_to_file>"
```
* **Deploy the WSP Solution for specific Web Application**
#### Open SharePoint Managment Shell as Admin
#### Install the solution with command

```powershell
Install-SPSolution -Identity <nameofsolution.wsp> -WebApplication <http://URLofWebApp> -GACDeployment
```
* **Unistall WSP Solution**

#### This is to undeploy solution from SP Farm, need be use before Remove SPSolution
#### Open SharePoint Managment Shell as Admin
#### Uninstall the solution with command

```powershell
Uninstall-SPSolution -Identity <nameofsolution.wsp> -WebApplication <http://URLofWebApp> -Confirm:$false
```
* **Remove WSP Solution**
#### Remove the WSP Solution from Farm after uninstall
#### Open SharePoint Managment Shell as Admin
#### Remove the solution with command

```powershell
Remove-SPSolution -Identity <nameofsolution.wsp> -Confirm:$false
```


* **Update WSP Solution with new version**
#### Open SharePoint Managment Shell as Admin
#### Update Solution

```powershell
 Update-SPSolution -Identity <nameofsolution.wsp> -LiteralPath "<path_to_file>" -GACDeployment -FullTrustBinDeployment
```

* **Export and Backup Solution**
#### Open SharePoint Managment Shell as Admin
#### Export single solution

```powershell
$farm = Get-SpFarm
$SolutionFile = $farm.Solutions.Item("SolutionName.wsp").SolutionFile
$SolutionFile.SaveAs("D:\SolutionFile.wsp")
```
* #### Backup all solution
[Backup Script](/SharePoint_Manage/SharePoint_BackupAllWSP.ps1)

* #### Quick Export
#### Open SharePoint Managment Shell as Admin

```powershell
$dirName = "C:\Temp\WSPSolutions_Export"
foreach ($solution in Get-SPSolution)
{
    $id = $Solution.SolutionID
    $title = $Solution.Name
    $filename = $Solution.SolutionFile.Name
    $solution.SolutionFile.SaveAs("$dirName\$filename")
}
```
