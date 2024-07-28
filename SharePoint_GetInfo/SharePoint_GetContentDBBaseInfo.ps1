# Show the Name of DB, Size, Count Site Collection and Web Application

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop

$DBS = Get-SPContentDatabase 
ForEach ($db in $dbs) {
    Write-Host "Name:"$db.Name -NoNewline `t -ForegroundColor Green 
    $size = $db.DiskSizeRequired 
    $sizeGB = [Math]::Round(($size / 1GB), 2)
    Write-Host "Size:"$sizeGB "GB" -NoNewline `t -ForegroundColor Yellow 
    Write-Host "SiteCount:"$db.CurrentSiteCount  -NoNewline `t -ForegroundColor Cyan
    Write-Host "WebApp:"$db.WebApplication.Name -ForegroundColor Magenta
}