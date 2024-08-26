#### Solution for remove corrupted Web Application

- Reference

[Article #1](https://infomoss.blogspot.com/2019/03/solution-unable-to-remove-corrupted-web.html)

[Article #2](https://tinysharepoint.wordpress.com/2020/09/09/cannot-delete-web-application/)

- Error when removing web app
- Note the WebAppName on error for use ahead

```txt
Remove-SPWebApplication : An object in the SharePoint administrative framework, “SPWebApplication Name=WebAppName”, could not be deleted because other objects depend on it. Update all of these dependants to point to null or different objects and
retry this operation. The dependant objects are as follows:
At line:1 char:1
+ Remove-SPWebApplication -Identity https://mywebapp -Confirm
```
- Query on SQL Instance note the WebApp ID
```sql
select * from Objects (nolock) where Name like '%WebAppName%' 
```
- Query for the GUID 
```sql
select * from SiteMap (nolock) where ApplicationId = 'WebAppID'
```
- From SharePoint Managment Shell
```PowerShell
$db = Get-SPContentDatabase -Identity ‘GUID’
$db.Delete()
```
- Now you can delete the Web Application
```PowerShell
Remove-SPWebApplication -Identity <URLWebApp> -DeleteIISSite
```
