<#

╔═╗┌─┐┬─┐┬┌─┐┌┬┐  ┌┐ ┬ ┬           
╚═╗│  ├┬┘│├─┘ │   ├┴┐└┬┘           
╚═╝└─┘┴└─┴┴   ┴   └─┘ ┴            
╔╦╗┬ ┬┌─┐┌┬┐┌─┐┌─┐  ╔═╗┌┬┐┌─┐┌┐┌┌┐┌
 ║ ├─┤│ ││││├─┤└─┐  ╠═╣│││├─┤││││││
 ╩ ┴ ┴└─┘┴ ┴┴ ┴└─┘  ╩ ╩┴ ┴┴ ┴┘└┘┘└┘
 
    .SYNOPSIS
        Connect Mg-Graph with the required permission to check Users Group membership for Standards IT Policies Security Group and add them.

    .DESCRIPTION
        Connect to Mg-Graph using 'User.ReadWrite.All','Directory.ReadWrite.All','GroupMember.ReadWrite.All','Group.ReadWrite.All','Directory.AccessAsUser.All' Permissions.
        List the current context.
        Search the 3 Standards Security Groups : COMPANY IT Policies, Service Accounts, Global-Admin and write the result.
        Import the CSV with the user list, note that the CSV needs to match the following naming convention : DisplayName, ObjectId, UPN.
        Write the number of items in the csv.


#>

<#
.FUNCTIONS
#>

#List the scope that contains *Group*
function Get-mggraphpermissionlist{
$SearchPermissions = Read-Host "Please type a keyword permission like : *Device*, you need to add the wildcard at the start and end to search the full string.`
You can type : Get-mggraphpermissionlist to relaunch the search with another keyword."
$ScopesList = Find-MgGraphPermission | ? { $_.Name -like $SearchPermissions } | Select-Object Name, Description
if($SearchPermissions -ne $true){
Write-Host "No input provided or no result found - skipped" -ForegroundColor Yellow
}else{
$ScopesList
}}

#Open Dialog box to select file
function Trigger-Dialog {
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog

if ($OpenFileDialog.ShowDialog() -ne "Cancel") {
    $OpenFileDialog.FileName
} else {
    Write-Host "No File Selected" -ForegroundColor Red
}
}

#Loop Through the CSV
function Action-GroupsMember {
#Check if each user is member of the Group and add it in membership if it is not the case
foreach ($i in $CSV){
#Get the current Group id membership of the user
    $UserGroupMembership = Get-MgUserMemberOf -UserId $i.Id
    #If User is already part of IT Policies skip and inform
    if ($UserGroupMembership.Id -contains $SearchITPolicy.Id){
    Write-Host "$($i.DisplayName) is already member of $($SearchITPolicy.DisplayName)" -ForegroundColor Green
    #If User is part of Service Accounts skip and inform
    }elseif($UserGroupMembership.Id -contains $SearchServiceAccount.Id){
    Write-Host "$($i.DisplayName) is member of $($SearchServiceAccount.DisplayName), it should not be part of IT Policies" -ForegroundColor Cyan
    #If User is part of Global Admin skip and inform
    }elseif($UserGroupMembership.Id -contains $SearchGlobalAdmin.Id){
    Write-Host "$($i.DisplayName) is member of $($SearchGlobalAdmin.DisplayName), it should not be part of IT Policies, there is a special Policy for Admin accounts" -ForegroundColor Cyan
    #Else try to add the User to IT Policies group
    }else{
    Write-Host "$($i.DisplayName) is not member of $($SearchITPolicy.DisplayName), trying to add to membership now." -ForegroundColor Yellow
    New-MgGroupMember -GroupId $SearchITPolicy.Id -DirectoryObjectId $i.Id 
}
}}

#Loop Through the single user
function Action-GroupsMemberSingle {
#Check if each user is member of the Group and add it in membership if it is not the case
$Identity = Get-MgUser -UserId $User

foreach ($i in $Identity){
#Get the current Group id membership of the user
    $UserGroupMembership = Get-MgUserMemberOf -UserId $i.Id
    #If User is already part of IT Policies skip and inform
    if ($UserGroupMembership.Id -contains $SearchITPolicy.Id){
    Write-Host "$($i.DisplayName) is already member of $($SearchITPolicy.DisplayName)" -ForegroundColor Green
    #If User is part of Service Accounts skip and inform
    }elseif($UserGroupMembership.Id -contains $SearchServiceAccount.Id){
    Write-Host "$($i.DisplayName) is member of $($SearchServiceAccount.DisplayName), it should not be part of IT Policies" -ForegroundColor Cyan
    #If User is part of Global Admin skip and inform
    }elseif($UserGroupMembership.Id -contains $SearchGlobalAdmin.Id){
    Write-Host "$($i.DisplayName) is member of $($SearchGlobalAdmin.DisplayName), it should not be part of IT Policies, there is a special Policy for Admin accounts" -ForegroundColor Cyan
    #Else try to add the User to IT Policies group
    }else{
    Write-Host "$($i.DisplayName) is not member of $($SearchITPolicy.DisplayName), trying to add to membership now." -ForegroundColor Yellow
    New-MgGroupMember -GroupId $SearchITPolicy.Id -DirectoryObjectId $i.Id 
}
}}

Get-mggraphpermissionlist

#Connect-MgGraph services with correct scopes, note you need Directory.AccessAsUser.All to run the script as Global Admin else you will have permission error.
$Scopes=@('User.ReadWrite.All','Directory.ReadWrite.All','GroupMember.ReadWrite.All','Group.ReadWrite.All','Directory.AccessAsUser.All')

Connect-MgGraph -Scopes $Scopes

Write-Host "Current scope of the account below" -ForegroundColor Yellow

$Context = Get-MgContext
$Context.Scopes

Write-Host "#------------------------------------------#" -ForegroundColor Yellow

#Search and display if there is a Standard Security Group for Managing IT Policy Members Staff
$SearchITPolicy = Get-MgGroup -All | ? {$_.DisplayName -like "*IT Policies"} | Select Id,DisplayName
$SearchServiceAccount = Get-MgGroup -All | ? {$_.DisplayName -like "*Service_Accounts*"} | Select Id,DisplayName
$SearchGlobalAdmin = Get-MgGroup -All | ? {$_.DisplayName -like "Global_Admin"} | Select Id,DisplayName
$SearchITPolicy
$SearchServiceAccount
$SearchGlobalAdmin

#Import CSV with User data and show how many user have an Intune License
$ConfirmCSV = Read-Host "Do you require the use of CSV file import ? Make sure the CSV have 3 headers : DisplayName,ObjectId,UPN - Type Y OR N" 

if ($ConfirmCSV -eq "Y") {
    $filePath = Trigger-Dialog
    if ($filePath) {
        $CSV = Import-Csv $filePath | Select-Object DisplayName, ObjectId, UPN
    } else {
        Write-Host "No CSV provided!" -ForegroundColor Red
    }
} else {
    Write-Host "CSV import skipped." -ForegroundColor Yellow
}

if ($CSV) {
    Write-Host "There are $($CSV.Count) Users in the CSV provided" -ForegroundColor Yellow
    Action-GroupsMember
} else {
$User = Read-Host "Type the email address of the user you want to check group membership and add"
    Action-GroupsMemberSingle
}

Disconnect-MgGraph