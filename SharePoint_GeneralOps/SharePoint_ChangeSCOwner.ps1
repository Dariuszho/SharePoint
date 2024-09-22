################################################################
# Change the Owner and Secondary Owner on All Site Collections #
################################################################

Clear-Host

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$Owner = Read-Host -Prompt "Provide the Owner in format domain\username"
$SecondaryOwner = Read-Host -Prompt "Provide the Secondary Owner in format domain\username"

$Sites = Get-SPSite -Limit All

foreach ($Site in $Sites) {

    Set-SPSite -Identity $Site -OwnerAlias $Owner -SecondaryOwnerAlias $SecondaryOwner
    
}
