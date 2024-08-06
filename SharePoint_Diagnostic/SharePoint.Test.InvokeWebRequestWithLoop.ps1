<#
.DESCRIPTION
Measure Web Request to specific site on SharePoint or any web site you need
The loop is configured with 10000 request , can change as you want
Keeping in file is optional and can be comment 
#>

$url = Read-Host 'Insert Web URL: '
$n = 0

While ($n -lt 10000) {
    # track execution time #
    $timeTaken = Measure-Command -Expression {
        Invoke-WebRequest -Uri $url 
    }
    # calculate to miliseconds and keep in file 
    $milliseconds = $timeTaken.TotalMilliseconds
    $milliseconds = [Math]::Round($milliseconds, 1) 
    $milliseconds | Out-File "C:\Temp\InvokeSite.txt" -Append
    $n++ 
}
