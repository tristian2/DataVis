# recursive walk sites and site collections
# run on ****shaula**** can be used to create the site structure on sharepoint online for the migration
# place results into csv for further analysis
# tristian o'brien
# 16/10/2018
# added size, locale and lastmodified
if ( (Get-PSSnapin -Name Microsoft.Sharepoint.Powershell -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin Microsoft.Sharepoint.Powershell
}
Clear-Host 
$filePath = "c:\sitestructure.csv"
try {
    $webApps = get-spwebapplication 
} catch {
    write-host "please make sure you are running on a sharepoint on premise server please"
}
$webApps = $webApps | Where-Object { $_.DisplayName -ne 'mysite' }
Clear-Content -path $filePath -force
Add-Content -Path $filePath -Value '"uri","parentweburi","title","description","locale","template","size","lastmodified"'

function GetFolderSize ($Folder)
{
    [long]$folderSize = 0 
    foreach ($file in $Folder.Files)
    {
        $folderSize += $file.Length;
    }
    foreach ($fd in $Folder.SubFolders)
    {
        $folderSize += GetFolderSize -Folder $fd
    }
    return $folderSize
}
function GetSubWebSizes ($Web)
{
    [long]$subtotal = 0
    foreach ($subweb in $Web.GetSubwebsForCurrentUser())
    {
        [long]$webtotal = 0
        foreach ($folder in $subweb.Folders)
        {
            $webtotal += GetFolderSize -Folder $folder
        }
        $subtotal += $webtotal
        $subtotal += GetSubWebSizes -Web $subweb
    }
    return $subtotal
}
function GetWebSize ($Web)
{
    [long]$subtotal = 0
    foreach ($folder in $Web.Folders)
    {
        $subtotal += GetFolderSize -Folder $folder
    }
 
    return $subtotal
}
function GetWebSizes ($StartWeb)
{
    $web = Get-SPWeb $StartWeb
    [long]$total = 0
    $total += GetWebSize -Web $web
    $total += GetSubWebSizes -Web $web
    $totalInMb = ($total/1024)/1024
    $totalInMb = "{0:N2}" -f $totalInMb
    $totalInGb = (($total/1024)/1024)/1024
    $totalInGb = "{0:N2}" -f $totalInGb
    $web.Dispose()
    return $totalInMb
}
foreach($webApp in $webApps)
{

    try {
        foreach($siteColl in $webApp.Sites) 
        { 
            foreach($web in $siteColl.AllWebs) 
            {                             
                $url = $web.Url
                $parentweburi = $web.ParentWeb.Url
                $title = $web.Title
                $description = $web.Description
                $locale = $web.Locale
                $webtemplate = $web.webtemplate
                $lastmodified = $web.LastItemModifiedDate  
                $size = GetWebSizes -StartWeb $url           
                Add-Content -Path  $filePath -Value  `"$url'","'$parentweburi'","'$title'","'$description'","'$locale'","'$webtemplate'","'$size'","'$lastmodified'"'                
            } 

        } 
    } catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName        
    }
}
