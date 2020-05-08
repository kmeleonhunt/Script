<#Synopsis 
#This script allow you to update Conference room Computers all at once.

#0 : Functions to compare HTML links from Dell.com to check new BIOS versions
#1 : First you'll be prompted to give your Credentials which will be saved into a variable for later use in the script. 
#2 : Test-Connection, will save the Computer into a txt file which will be used later for reference.
      #  Then a first loop begin to ping every computer and see if they are up and running.
#3 : Get all the SerialNumber last 4 digit to be added to BIOS PWD.
#4 : Set Path variables for copying files to remote machine, copy the files according to their system info.
#5 : Suspend Bitlocker, will re-enable it next boot.
#6 : Launch BIOS updates according to the Computer Model and BIOS Version.
#7 : Ping connection on each machine to see if the BIOS update is still running.
       # Once the machine is pinging it means the BIOS update is over.
#8 : Remove all installation files after the update
#>


#####
#LOG#
#####

$LogFile ='\\psys35cdp10\Share\Script\Update-All-BIOS-CR\LOGS.log' 

if (Test-path -path $LogFile) {
Remove-item -path $LogFile
}

Start-Transcript -Path $LogFile 

#0#

#HTLM Driver comparaison for Optiplex 7050#

###GET OPTIPLEX 7050 HTML LINKS FOR BIOS DOWNLOAD###

Function GET-Optiplex7050_BIOS_UPDATE {

$DellrootHTML = "http://downloads.dell.com"

Write-Host "<=	Indicates that property value appears only in the -ReferenceObject set." -ForegroundColor Magenta
Write-Host "=>	Indicates that property value appears only in the -differenceObject." -ForegroundColor Magenta

$OldVer = $(Get-content "#Insert Your Path Here") #You have to make a single query once to save that file as a reference object

$NEW = Invoke-WebRequest -uri http://downloads.dell.com/published/pages/optiplex-7050-desktop.html #Optiplex as an example, search your own devices !
$NEW.links.href | ? {$_ -like "*String value*"} | Out-file "#Insert Your Path Here" #Save the href output into txt for comparaison 

$NEWVer = $(Get-Content "#Insert Your Path Here") #New href links for compare-Object

$CompResult = (Compare-Object $OldVer $NEWVer -IncludeEqual) #Compare Old vs New if New have different strings you will see an output


###Compare the OLD and NEW Result and show if new are available###


Foreach ($i in $CompResult) { #Select the new links and launch the download 

    if ($i.SideIndicator -like "*=>*" -eq $true) 
        {Write-host "$i NEW DRIVER" -ForegroundColor Yellow
        

        ###ASK USER TO CHOOSE THE CORRECT DATA TO LAUNCH THE DOWNLOAD##

        $Fullpath = $DellrootHTML + $i.InputObject

        $FileName = $i.InputObject

        Invoke-WebRequest -uri $Fullpath -Outfile "#Insert Your Path Here" 

        Write-Output "This is the date $(get-date -f yyyy-MM-dd) the latest bios was downloaded from Dell. BIOS version currently in is : $i" |
        Out-file "#Insert Your Path Here"
        }

        else{
        Write-host "$i is old Driver for Optiplex 7050" }
}

}

#1#

#This ask for your credentials and save them into a variable that you need to call with Invoke-command later in the script

Function Provide-Cred {
Write-Host "Please provide your credentials so the script can continue." -ForegroundColor Yellow
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
# Extract the current user's domain and also pre-format the user name to be used in the credential prompt.
$UserDomain = $env:USERDOMAIN
$UserName = "$UserDomain\$env:USERNAME"
# Define the starting number (always #1) and the desired maximum number of attempts, and the initial credential prompt message to use.
$Attempt = 1
$MaxAttempts = 5
$CredentialPrompt = "Enter your Domain account password (attempt #$Attempt out of $MaxAttempts):"
# Set ValidAccount to false so it can be used to exit the loop when a valid account is found (and the value is changed to $True).
$ValidAccount = $False

# Loop through prompting for and validating credentials, until the credentials are confirmed, or the maximum number of attempts is reached.
Do {
    # Blank any previous failure messages and then prompt for credentials with the custom message and the pre-populated domain\user name.
    $FailureMessage = $Null
    $Credentials = Get-Credential -UserName $UserName -Message $CredentialPrompt
    # Verify the credentials prompt wasn't bypassed.
    If ($Credentials) {
        # If the user name was changed, then switch to using it for this and future credential prompt validations.
        If ($Credentials.UserName -ne $UserName) {
            $UserName = $Credentials.UserName
        }
        # Test the user name (even if it was changed in the credential prompt) and password.
        $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
        Try {
            $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ContextType,$UserDomain
        } Catch {
            If ($_.Exception.InnerException -like "*The server could not be contacted*") {
                $FailureMessage = "Could not contact a server for the specified domain on attempt #$Attempt out of $MaxAttempts."
            } Else {
                $FailureMessage = "Unpredicted failure: `"$($_.Exception.Message)`" on attempt #$Attempt out of $MaxAttempts."
            }
        }
        # If there wasn't a failure talking to the domain test the validation of the credentials, and if it fails record a failure message.
        If (-not($FailureMessage)) {
            $ValidAccount = $PrincipalContext.ValidateCredentials($UserName,$Credentials.GetNetworkCredential().Password)
            If (-not($ValidAccount)) {
                $FailureMessage = "Bad user name or password used on credential prompt attempt #$Attempt out of $MaxAttempts."
            }
        }
    # Otherwise the credential prompt was (most likely accidentally) bypassed so record a failure message.
    } Else {
        $FailureMessage = "Credential prompt closed/skipped on attempt #$Attempt out of $MaxAttempts."
    }
 
    # If there was a failure message recorded above, display it, and update credential prompt message.
    If ($FailureMessage) {
        Write-Warning "$FailureMessage"
        $Attempt++
        If ($Attempt -lt $MaxAttempts) {
            $CredentialPrompt = "Authentication error. Please try again (attempt #$Attempt out of $MaxAttempts):"
        } ElseIf ($Attempt -eq $MaxAttempts) {
            $CredentialPrompt = "Authentication error. THIS IS YOUR LAST CHANCE (attempt #$Attempt out of $MaxAttempts):"
        }
    }
} Until (($ValidAccount) -or ($Attempt -gt $MaxAttempts))
}

#2#

#####################
###Test-Connection###
#####################

Function Test-Connection {
Get-ADComputer -Filter * -SearchBase '#Insert Active Directory Path' | 
 select -ExpandProperty Name | Out-file '#Insert your path'

(gc "#your path") -replace " " ,"" | set-content "#your path"

$computertxt = gc "#your path"

foreach ($Name in $computertxt){

$pingresult = ping $_.Name -count 1 -ErrorAction SilentlyContinue 

if ($pingresult -ne $_.Exception){
write-host "$name is ONLINE" -ForegroundColor Green
}
Else {
write-host "$name is OFFLINE" -ForegroundColor Red
}
}
}

#######################################
####Copy the files to each computer####
#######################################

Function FTP-Files {

Write-Progress -Activity "Creating variables path...copy files to remote 5%" -PercentComplete 5

$Server4 = "#your path"
$Server5 = "#your path"
$Server6 = "#your path"

$Results2 = @{}
Foreach ($name in $Computertxt) {
Try{
$ST = (gwmi -ErrorAction Stop -computername $name win32_BIOS).serialnumber.substring(3)
$BIOSver = (gwmi -ErrorAction Stop -computername $name win32_bios).SMBIOSBIOSVersion
$LMModel = (gwmi -ErrorAction Stop -computername $name win32_Computersystem).Model 
$BIOSPWD = "#Insert your password here"
$Destination = "\\$Name\c$\"
$Results3[$Name] = $ST

if ($LMModel -match "#String value" -and $BIOSver -notmatch "#Bios ver value" ) {copy-item $server4 $destination -Force
write-host "#Insert Model match ! for $name" -ForegroundColor Green}
elseif ($LMModel -ne "Optiplex 7050") {Write-host "$name is not an Optiplex 7050" -ForegroundColor Magenta}

if ($LMModel -match "Optiplex 7060" -and $BIOSver -notmatch "1.4.2" ) {copy-item $server5 $destination -Force
write-host "Optiplex 7060 match ! for $name" -ForegroundColor Green}
elseif ($LMModel -ne "Optiplex 7060") {Write-host "$name is not an Optiplex 7060" -ForegroundColor Magenta}

if ($LMModel -match "Optiplex 7070" -and $BIOSver -notmatch "1.2.1") {copy-item $server6 $destination -Force
write-host "Optiplex 7070 match ! for $name" -ForegroundColor Green}
elseif ($LMModel -ne "Optiplex 7070") {Write-host "$name is not an Optiplex 7070" -ForegroundColor Magenta}

else {write-host "The Bios executable has been transfered !" -ForegroundColor Green}
}
catch [System.Runtime.InteropServices.COMException] {

Write-Host "$name COM Error!" -ForegroundColor Red 
}
catch {

Write-Host "$name Unhandled Exception!" -ForegroundColor Red
}
}
}

#5#

########################################
##Suspend Bitlocker BEFORE BIOS UPDATE##
######################################## 

Function Suspend-BitLocker {
Write-Progress -Activity "Suspending bitlocker...10%" -PercentComplete 10

foreach ($name in $computertxt) {

Try{
Invoke-command -computername $name -credential $Credentials -Scriptblock {
    Suspend-bitlocker -mountpoint "C:" -rebootcount 1 
}
}
catch [System.Runtime.InteropServices.COMException] {

Write-Host "$name COM Error!" -ForegroundColor Red 
}
catch {

Write-Host "$name Unhandled Exception!" -ForegroundColor Red
}
}
}

#6#

#######################
##Launch BIOS updates##
#######################

Function Launch-BIOS-Updates {

Write-Progress -Activity "Installing BIOS update...40%" -PercentComplete 40
write-host "Starting BIOS updates for #Insert your model name" -ForegroundColor Green

foreach ($name in $computertxt) {
Try{
Invoke-command -computername $Name -credential $Credentials -Scriptblock { 
    cmd /k start /wait C:\#Yournamefilestatedat the beginning.exe /s /p=$using:BIOSPWD /r
        $LASTEXITCODE
}

if ($LMModel -match "Optiplex 7060"-and $BIOSver -ne "1.4.2")  {
write-host "Starting BIOS updates for 7060" -ForegroundColor Green
Invoke-command -computername $Name -credential $Credentials -Scriptblock { 
    cmd /k start /wait C:\BIOS7060.exe /s /p=$using:BIOSPWD /r
}

if ($LMModel -match "Optiplex 7070"-and $BIOSver -ne "1.2.1") {
write-host "Starting BIOS updates for 7070" -ForegroundColor Green
Invoke-command -computername $Name-credential $Credentials -Scriptblock { 
    cmd /k start /wait C:\BIOS7070.exe /s /p=$using:BIOSPWD /r
}

else {
write-host "BIOS no match for $name ...update canceled..." -ForegroundColor Magenta 
}
}
}
}
catch [System.Runtime.InteropServices.COMException] {

Write-Host "$name COM Error!" -ForegroundColor Red 
}
catch {

Write-Host "$name Unhandled Exception!" -ForegroundColor Red
}
}
}

#7#
#UPDATE PROGRESS#

Function See-State {

Write-Progress -Activity "Script paused for 30 sec...45%" -PercentComplete 45
write-host ("BIOS updates Launching...Please wait...") -ForegroundColor Cyan
Start-Sleep -s 30

Write-Progress -Activity "BIOS updates on the run...50%" -PercentComplete 50

foreach ($name in $computertxt) {
 while($ping1 = ping $name -n 1 | Where-Object {$_ -match "Request timed out"})
 {
 write-host ("~(˘▾˘~) ...BIOS update on the run for $Name, please wait... (~˘▾˘)~") -ForegroundColor Yellow
 }
 if ($ping1 = ping $name -n 1 | Where-Object {$_ -ne "Request timed out"}){
 write-host "BIOS update is over for $name" -ForegroundColor Cyan
 }
 }
 }

#8#

#Replace Old HTML file for reference#

 $OLD = Invoke-WebRequest -uri http://downloads.dell.com/published/pages/optiplex-7050-desktop.html 
$OLD.links.href | ? {$_ -like "*Optiplex_7050_*"} | Out-file "#your path" 

 $OLD = Invoke-WebRequest -uri http://downloads.dell.com/published/pages/optiplex-7050-desktop.html 
$OLD.links.href | ? {$_ -like "*Optiplex_7060_*"} | Out-file "#your path"

 $OLD = Invoke-WebRequest -uri http://downloads.dell.com/published/pages/optiplex-7050-desktop.html 
$OLD.links.href | ? {$_ -like "*Optiplex_7070_*"} | Out-file "#your path"

##Remove Installation files

Invoke-command -computername $Computer -credential $Credentials -Scriptblock {

foreach ($name in $computertxt){

Remove-Item "C:\BIOS7050.exe" -Recurse -ErrorAction Ignore
Remove-Item "C:\BIOS7060.exe" -Recurse -ErrorAction Ignore
Remove-Item "C:\BIOS7070.exe" -Recurse -ErrorAction Ignore

}
}

 Write-Progress -Activity "BIOS update finnished, 100%" -Complete 
 Stop-Transcript