Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell -DisableNameChecking
$SharepointAdminURL = 'https://shouldhavedonethissooner-admin.sharepoint.com'
Connect-SPOService -Url $SharepointAdminURL -UseSystemBrowser $true

$allsites = get-sposite -limit all
[int]$allsitescount = $allsites.count

# Get Batch Delete Status
$list = new-object 'collections.generic.list[psobject]'
[int]$i = 0
Foreach ($siteUrl in $allsites.url){
    $list.add($(Get-SPOSiteFileVersionBatchDeleteJobProgress -Identity $siteUrl | select-object url,Status,FilesProcessed,StorageReleasedInBytes,@{name='ReleasedGB';Expression={[math]::Round(((($_.StorageReleasedInBytes / 1000)/1000)/1000),2)}}))
    $i++
    Write-output "$i of $allsitescount" 
}
($list.ReleasedGB | Measure-Object -sum).sum

# order Cleanup of 'NoRequestFound' sites
[int]$ii = 0
[int]$nocleanupcount = ($list | where-object -property status -eq 'NoRequestFound').count

Foreach ($siteUrl in ($list | where-object -property status -eq 'NoRequestFound').url){
    Set-SPOSite -Identity $siteUrl -EnableAutoExpirationVersionTrim $true -confirm:$false
    New-SPOSiteFileVersionBatchDeleteJob -Identity $siteUrl -Automatic -confirm:$false
    $ii++
    Write-output "$ii of $nocleanupcount"
}