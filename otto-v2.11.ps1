<#
NAME: 	otto
AUTHOR:	david.kruger@ssc-spc.gc.ca

CHANGE LOG:
1.0:  dk - first version release
1.1:  dk - update usage to include addroles
1.2:  dk - display help if -do not entered; ask for input filename and verify
2.0:  dk - combine add,remove licenses, add form and listbox
2.1:  dk - addroles add form and listbox, add Active and Eligible, added as-is note
2.2:  dk - combine adduser,removeuser,disableuser,enableuser with choice, add x months endate
2.3:  dk - map ProductName, GUID and StringId for licenses for clarity using 'official' msft csv
	    - signins add choices for all users, input file users, and search DisplayName
2.4:  dk - add regex for mailnickname, removed $daveDirRoles, fix "Missing '=' operator after key in hash literal" in $daveDirTemplateRoles
	    - moved StringId out of listbox (kept in script for reference) to make choosing licenses easier to read
	    - changed eligible end date from months to days, fix $searchy
2.5:  dk - add AccountEnabled column to signins spreadsheet, add switch to fix unexpected user input for -do, make Get-Inputfile a function to only ask when needed
2.6:  db - added scopes call to Connect-MGGraph to get session permissions
2.7:  db - for 'users' selection moved file input to subroutines and added transcript
2.8:  dk - update scopes "Directory.AccessAsUser.All", replace Select with Select-Object, removed variable $dave (was assigned but not used),
           add List Roles
2.9:  dk - output List Roles in english, remove 163dev from signin output filename
2.10: dk - fix to List Roles
2.11: dk - speed improvement to List Roles

TESTED ON:
PowerShell 5.1.22621.4249, Microsoft Graph 2.22.0
PowerShell 7.4.5, Microsoft Graph 2.23.0

KNOWN ISSUES/BUGS:
choice doesn't work in ISE
forms don't work in vscode

WISHLIST:
transcript (logging), error handling
function for single form
adduser get additional unique properties from import-csv - displayname, justification, dept
removeroles
enable my global admin role
move connect-mggraph and it's scope to each subroutine, grant least permissions as needed

NOTE:
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL DAVE OR DAN
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.
#>

#####################################################################################

 param (
 [string]$do
 #[Parameter(Mandatory=$true)][string]$do
 )

function Get-Inputfile {

    $global:bunchofusersfilename = Read-Host "enter filename of your input file"

    if (!(Test-Path -pathtype leaf $bunchofusersfilename)) {
        write-output "`notto can't find $bunchofusersfilename"
    exit
    }

    $global:bunchofusers=Get-Content $bunchofusersfilename
}


#####################################################################################

<#
-removed Microsoft Teams Exploratory Dept = 'e0dfc8b9-9531-4ec8-94b4-9fec23b05fc8' - cannot be assigned or removed from users or groups
-can't add Teams Rooms Pro and Teams Rooms Basic together - License assignment failed because service plans are mutually exclusive
-TEST_M365_LIGHTHOUSE_PARTNER_PLAN1 = '37c86dd4-ca27-4f07-8abc-fdf4a34d986c' not in msft productnames.csv
-Microsoft_Teams_Premium_intelligence =	'0bfba3eb-669a-40d0-9375-e9da553023bd' not in msft productnames.csv
#>
                
$daveSkus = @{
'Microsoft Defender for Office 365 (Plan 1)' = '4ef96642-f096-40de-a3e9-d83fb2f90211'  #[ATP_ENTERPRISE]
'Microsoft Defender for Endpoint P1' = '16a55f2f-ff35-4cd5-9146-fb784e3761a5'  #[DEFENDER_ENDPOINT_P1]
'Enterprise Mobility + Security E3' = 'efccb6f7-5641-4e0e-bd10-b4976e1bf68e'  #[EMS]
'Enterprise Mobility + Security E5' = 'b05e124f-c7cc-45a0-a6aa-8cf78c946968'  #[EMSPREMIUM]
'Office 365 E3' = '6fd2c87f-b296-42f0-b197-1e91e994b900'  #[ENTERPRISEPACK]
'Office 365 E5' = 'c7df2760-2c81-4ef7-b578-5b5392b571df'  #[ENTERPRISEPREMIUM]
'Microsoft Power Automate Free' = 'f30db892-07e9-47e9-837c-80727f46fd3d'  #[FLOW_FREE]
'Microsoft 365 E5 Suite features' = '99cc8282-2f74-4954-83b7-c6a9a1999067'  #[M365_E5_SUITE_COMPONENTS]
'Microsoft Teams Shared Devices' = '295a8eb0-f78d-45c7-8b5b-1eed5ed02dff'  #[MCOCAP]
'Microsoft 365 E3 Extra Features' = 'f5b15d67-b99e-406b-90f1-308452f94de6'  #[Microsoft_365_E3_Extra_Features]
'Microsoft Teams Audio Conferencing with dial-out to USA/CAN' = '1c27243e-fb4d-42b1-ae8c-fe25c9616588'  #[Microsoft_Teams_Audio_Conferencing_select_dial_out]
'Microsoft Teams Rooms Basic' =   '6af4b3d6-14bb-4a2a-960c-6c902aad34f3'  #[Microsoft_Teams_Rooms_Basic]
'Microsoft Teams Rooms Pro' =   '4cde982a-ede4-4409-9ae6-b003453c8ea6'  #[Microsoft_Teams_Rooms_Pro]
'Microsoft Teams Phone Resource Account' = '440eaaa8-b3e0-484b-a8be-62870b9ba70a'  #[PHONESYSTEM_VIRTUALUSER]
'Microsoft Fabric (Free)' =   'a403ebcc-fae0-4ca2-8c8c-7a907fd6c235'  #[POWER_BI_STANDARD]
'Dynamics 365 Business Central for IWs' = '6a4a1628-9b9a-424d-bed5-4118f0ede3fd'  #[PROJECT_MADEIRA_PREVIEW_IW_SKU]
'Microsoft Stream' = '1f2f344a-700d-42c9-9427-5cea1d5d7ba6'  #[STREAM]
'Microsoft Defender for Endpoint' = '111046dd-295b-4d6d-9724-d52ac90bd1f2'  #[WIN_DEF_ATP]
'Windows 10/11 Enterprise E3' = '6a0f6da5-0b87-4190-a6ae-9bb5a2b9546a'  #[Win10_VDA_E3]
'Windows 10/11 Enterprise E5' = '488ba24a-39a9-4473-8ee5-19291e71b002'  #[WIN10_VDA_E5]
'Windows Store for Business' = '6470687e-a428-4b7a-bef2-8a291ad947c9'  #[WINDOWS_STORE]
}

$daveDirTemplateRoles = @{
'Application Administrator' = '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3'
'Application Developer' = 'cf1c38e5-3621-4004-a7cb-879624dced7c'
'Authentication Administrator' = 'c4e39bd9-1100-46d3-8c65-fb160da0071f'
'Authentication Extensibility Administrator' = '25a516ed-2fa0-40ea-a2d0-12923a21473a'
'Authentication Policy Administrator' =	'0526716b-113d-4c15-b2c8-68e3c22b9f80'
'Azure AD Joined Device Local Administrator' = '9f06204d-73c1-4d4c-880a-6edb90606fd8'
'Azure DevOps Administrator' = 'e3973bdf-4987-49ae-837a-ba8e231c7286'
'Azure Information Protection Administrator' = '7495fdc4-34c4-4d15-a289-98788ce399fd'
'B2C IEF Keyset Administrator' = 'aaf43236-0c0d-4d5f-883a-6955382ac081'
'B2C IEF Policy Administrator' = '3edaf663-341e-4475-9f94-5c398ef6c070'
'Billing Administrator' = 'b0f54661-2d74-4c50-afa3-1ec803f12efe'
'Cloud Application Administrator' = '158c047a-c907-4556-b7ef-446551a6b5f7'
'Cloud Device Administrator' = '7698a772-787b-4ac8-901f-60d6b08affd2'
'Compliance Administrator' = '17315797-102d-40b4-93e0-432062caca18'
'Compliance Data Administrator' = 'e6d1a23a-da11-4be4-9570-befc86d067a7'
'Conditional Access Administrator' = 'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9'
'Customer LockBox Access Approver' = '5c4f9dcd-47dc-4cf7-8c9a-9e4207cbfc91'
'Desktop Analytics Administrator' = '38a96431-2bdf-4b4c-8b6e-5d3d8abac1a4'
'Directory Readers' = '88d8e3e3-8f55-4a1e-953a-9b9898b8876b'
'Directory Synchronization Accounts' = 'd29b2b05-8046-44ba-8758-1e26182fcf32'
'Directory Writers' = '9360feb5-f418-4baa-8175-e2a00bac4301'
'Dynamics 365 Administrator' = '44367163-eba1-44c3-98af-f5787879f96a'
'Exchange Administrator' = '29232cdf-9323-42fd-ade2-1d097af3e4de'
'Exchange Recipient Administrator' = '31392ffb-586c-42d1-9346-e59415a2cc4e'
'External ID User Flow Administrator' = '6e591065-9bad-43ed-90f3-e9424366d2f0'
'External ID User Flow Attribute Administrator' = '0f971eea-41eb-4569-a71e-57bb8a3eff1e'
'External Identity Provider Administrator' = 'be2f45a1-457d-42af-a067-6ec1fa63bc45'
'Fabric Administrator' = 'a9ea8996-122f-4c74-9520-8edcd192826c'
'Global Administrator' = '62e90394-69f5-4237-9190-012177145e10'
'Global Reader' = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
'Groups Administrator' = 'fdd7a751-b60b-444a-984c-02652fe8fa1c'
'Guest Inviter' = '95e79109-95c0-4d8e-aee3-d01accf2d47b'
'Helpdesk Administrator' = '729827e3-9c14-49f7-bb1b-9608f156bbb8'
'Hybrid Identity Administrator' = '8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2'
'Insights Administrator' = 'eb1f4a8d-243a-41f0-9fbd-c7cdf6c5ef7c'
'Intune Administrator' = '3a2c62db-5318-420d-8d74-23affee5d9d5'
'Kaizala Administrator' = '74ef975b-6605-40af-a5d2-b9539d836353'
'License Administrator' = '4d6ac14f-3453-41d0-bef9-a3e0c569773a'
'Message Center Privacy Reader' = 'ac16e43d-7b2d-40e0-ac05-243ff356ab5b'
'Message Center Reader' = '790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b'
'Network Administrator' = 'd37c8bed-0711-4417-ba38-b4abe66ce4c2'
'Office Apps Administrator' = '2b745bdf-0803-4d80-aa65-822c4493daac'
'Password Administrator' = '966707d0-3269-4727-9be2-8c3a10f19b9d'
'Power Platform Administrator' = '11648597-926c-4cf3-9c36-bcebb0ba8dcc'
'Printer Administrator' = '644ef478-e28f-4e28-b9dc-3fdde9aa0b1f'
'Printer Technician' = 'e8cef6f1-e4bd-4ea8-bc07-4b8d950f4477'
'Privileged Authentication Administrator' = '7be44c8a-adaf-4e2a-84d6-ab2649e08a13'
'Privileged Role Administrator' = 'e8611ab8-c189-46e8-94e1-60213ab1f814'
'Reports Reader' = '4a5d8f65-41da-4de4-8968-e035b65339cf'
'Search Administrator' = '0964bb5e-9bdb-4d7b-ac29-58e794862a40'
'Search Editor' = '8835291a-918c-4fd7-a9ce-faa49f0cf7d9'
'Security Administrator' = '194ae4cb-b126-40b2-bd5b-6091b380977d'
'Security Operator' = '5f2222b1-57c3-48ba-8ad5-d4759f1fde6f'
'Security Reader' = '5d6b6bb7-de71-4623-b4af-96380a352509'
'Service Support Administrator' = 'f023fd81-a637-4b56-95fd-791ac0226033'
'SharePoint Administrator' = 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c'
'Skype for Business Administrator' = '75941009-915a-4869-abe7-691bff18279e'
'Teams Administrator' =	'69091246-20e8-4a56-aa4d-066075b2a7a8'
'Teams Communications Administrator' = 'baf37b3a-610e-45da-9e62-d9d1e5e8914b'
'Teams Communications Support Engineer' = 'f70938a0-fc10-4177-9e90-2178f8765737'
'Teams Communications Support Specialist' = 'fcf91098-03e3-41a9-b5ba-6f0ec8188a12'
'Teams Devices Administrator' =	'3d762c5a-1b6c-493f-843e-55a3b42923d4'
'Teams Telephony Administrator' = 'aa38014f-0993-46e9-9b45-30501a20909d'
'Usage Summary Reports Reader' = '75934031-6c7e-415a-99d7-48dbd49e875e'
'User Administrator' = 'fe930be7-5e62-47db-91af-98c3a49a38b1'
}

################################## lets go!
$now = get-date -f "yyyy-MMM-dd-HHmmss"

######################### Connect to MS Graph SDK with all required permissions

$scopes = @(
   "AuditLog.Read.All",
   "User.Read.All",
   "User.ReadWrite.All",
   "User.ManageIdentities.All",
   "User.EnableDisableAccount.All",
   "LicenseAssignment.ReadWrite.All",
   "RoleManagement.ReadWrite.Directory",
   "RoleManagement.ReadWrite.Exchange"
   "Directory.AccessAsUser.All"
    )

Connect-MgGraph -Scopes $scopes -NoWelcome

switch ($do) {

################################## signins
"signins" {

    $msg = 'Do you want a report for [A]ll tenant users, [I]nput file users, or [S]earch within Displayname'
    choice /c ais /m $msg
    $response = $LASTEXITCODE

    if ($response -eq 1) {

        Get-MgUser -All -property DisplayName, UserPrincipalName, AccountEnabled, SignInActivity | Select-Object -ExpandProperty SignInActivity  DisplayName,UserPrincipalName,AccountEnabled | Select-Object DisplayName,UserPrincipalName, AccountEnabled, LastSignInDateTime, LastSuccessfulSignInDateTime, LastNonInteractiveSignInDateTime | sort-object DisplayName | export-csv "$now.signins-all.csv" -NoTypeInformation
    }

    if ($response -eq 2) {

        Get-Inputfile

        foreach ($user in $bunchofusers) {
            $getuserGUID = Get-Mguser -UserID $user
            Get-MgUser -UserId $getuserGUID.Id -property DisplayName, UserPrincipalName,AccountEnabled, SignInActivity | Select-Object -ExpandProperty SignInActivity DisplayName,UserPrincipalName,AccountEnabled | Select-Object DisplayName,UserPrincipalName, AccountEnabled, LastSignInDateTime, LastSuccessfulSignInDateTime, LastNonInteractiveSignInDateTime | sort-object DisplayName | export-csv "$now.signins-$bunchofusersfilename.csv" -append -NoTypeInformation
        }
    }

    if ($response -eq 3) {

        $searchy = Read-Host "enter search text you are looking for"
	    $thing = "DisplayName:$searchy"        
        Get-MgUser -consistencylevel eventual -Search $thing -All -property DisplayName, UserPrincipalName,AccountEnabled, SignInActivity | Select-Object -ExpandProperty SignInActivity DisplayName,UserPrincipalName,AccountEnabled | Select-Object DisplayName,UserPrincipalName, AccountEnabled,LastSignInDateTime, LastSuccessfulSignInDateTime, LastNonInteractiveSignInDateTime | sort-object DisplayName | export-csv "$now.signins-$searchy.csv" -NoTypeInformation
    }

    exit

} #signins


################################## add/remove/enable/disable users
"users" {

    $msg = 'Do you want to [A]dd, [R]emove, [E]nable, or [D]isable user accounts'
    choice /c ared /m $msg
    $response = $LASTEXITCODE

    if ($response -eq 1) {

        #mailnickname required, usagelocation required for assigning licensing
        
        Get-Inputfile
        Start-Transcript -path ".\$now.add-users-transcript.txt" -NoClobber -Append

        foreach ($user in $bunchofusers) {
            $mnn = $user -replace '(.*)@(.*)','$1'
            $PasswordProfile = @{ Password = 'abcdefghijklmnop12345!@#$%' }
            Write-Host "Add user " $user
            New-MgUser -DisplayName $user -PasswordProfile $PasswordProfile -AccountEnabled -UserPrincipalName $user -UsageLocation "CA" -MailNickName $mnn
        }
    }

    if ($response -eq 2) {
        
        
        Get-Inputfile
        Start-Transcript -path ".\$now.delete-users-transcript.txt" -NoClobber -Append

        foreach ($user in $bunchofusers) {
            Write-Host "Delete user " $user
            Remove-MgUser -UserId $user #-verbose #-confirm
        }
    }

    if ($response -eq 3) {
        
                Get-Inputfile
                Start-Transcript -path ".\$now.enable-users-transcript.txt" -NoClobber -Append

        foreach ($user in $bunchofusers) {
            Write-Host "Enable user " $user
            Update-MgUser -UserId $user -AccountEnabled:$true
        }
    }

    if ($response -eq 4) {

        Get-Inputfile
        Start-Transcript -path ".\$now.disable-users-transcript.txt" -NoClobber -Append

        foreach ($user in $bunchofusers) {
            Write-Host "Disable user " $user
            Update-MgUser -UserId $user -AccountEnabled:$false
        }
    }
Stop-Transcript
} #users

################################## add/remove licenses

"licenses" {

   Get-Inputfile

   $msg = 'Do you want to [A]dd or [R]emove licenses'
   choice /c ar /m $msg
   $response = $LASTEXITCODE

   #GUI time! create form and listbox
   Add-Type -AssemblyName System.Windows.Forms
   Add-Type -AssemblyName System.Drawing

   $form = New-Object System.Windows.Forms.Form
   $form.Text = 'Dave Loves List Boxes'
   $form.Size = New-Object System.Drawing.Size(385,320) #385,320
   $form.StartPosition = 'CenterScreen'

   $OKButton = New-Object System.Windows.Forms.Button
   $OKButton.Location = New-Object System.Drawing.Point(10,250) #10,250
   $OKButton.Size = New-Object System.Drawing.Size(75,23)
   $OKButton.Text = 'OK'
   $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
   $form.AcceptButton = $OKButton
   $form.Controls.Add($OKButton)

   $CancelButton = New-Object System.Windows.Forms.Button
   $CancelButton.Location = New-Object System.Drawing.Point(85,250) #85,250 (add 75)
   $CancelButton.Size = New-Object System.Drawing.Size(75,23)
   $CancelButton.Text = 'Cancel'
   $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
   $form.CancelButton = $CancelButton
   $form.Controls.Add($CancelButton)

   $label = New-Object System.Windows.Forms.Label
   $label.Location = New-Object System.Drawing.Point(10,20)
   $label.Size = New-Object System.Drawing.Size(280,20)
   $label.Text = 'Please select from the list below:'
   $form.Controls.Add($label)

   $listBox = New-Object System.Windows.Forms.Listbox
   $listBox.Location = New-Object System.Drawing.Point(10,40)
   $listBox.Size = New-Object System.Drawing.Size(350,50) #350,50
   $listBox.SelectionMode = 'MultiExtended'

   #load sorted daveSkus keys into listbox
   $bob=$daveSkus.Keys | sort-object
   
   foreach ($thing in $bob) {
      [void] $listBox.Items.Add($thing)
   }

   $listBox.Height = 200
   $form.Controls.Add($listBox)
   $form.Topmost = $true

   $daveform = $form.ShowDialog()

   if ($daveform -eq [System.Windows.Forms.DialogResult]::OK) {

      foreach ($user in $bunchofusers) {

         foreach ($davekey in $listBox.SelectedItems){
	 
	        if ($response -eq 1) {
    	           write-output "adding licenses..."
    	           Set-MgUserLicense -userid $user -AddLicenses @{SkuId = $daveSkus[$davekey]} -RemoveLicenses @()
    	     } 

	        if ($response -eq 2) {
    	           write-output "removing licenses..."
   	           Set-MgUserLicense -userid $user -RemoveLicenses @($daveSkus[$davekey]) -AddLicenses @()
    	     } 

         } # foreach key
      } # foreach user
   } # if result eq ok
} # licenses

################################## roles

"roles" {

Get-Inputfile

$msg = 'Do you want to add [A]ctive -no end date, add [E]ligible -with end date assignment, or [L]ist all roles assigned to user'
choice /c ael /m $msg
$response = $LASTEXITCODE

if ($response -eq 2) {
      $days = Read-Host "enter number of days for the assignment (ex: 90) (max:365)"
}

if ($response -eq 3) {

    Start-Transcript -path ".\$now.list-roles-transcript.txt" -NoClobber -Append

    write-host "`nWARNING: Works for 163dev.onmicrosoft.com and 163dev.ssclab.ca but NOT for ssctest.itsso.gc.ca users."
    write-host "please wait... getting active role assignments (1/2):"
    $getactive = Get-MgRoleManagementDirectoryRoleAssignment -all
    write-host "please wait... getting eligible role assignments (2/2):"
    $geteligible = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -all
    write-host "done"

    foreach ($user in $bunchofusers) {

        $PrincipalId = (Get-Mguser -UserID $user).Id
    
        write-host "`nActive Assignments for $user ($PrincipalId):"
        $boo =($getactive | ? {$_.PrincipalId -eq "$PrincipalId"}).RoleDefinitionId
                
        foreach ($ezkey in $boo){
            $daveDirTemplateRoles.Keys |? { $daveDirTemplateRoles[$_] -eq $ezkey }    
        }
        
        write-host "`nEligible Assignments for $user ($PrincipalId):"
        $boo2 =($geteligible | ? {$_.PrincipalId -eq "$PrincipalId"}).RoleDefinitionId
        
        foreach ($ezkey in $boo2){
            $daveDirTemplateRoles.Keys |? { $daveDirTemplateRoles[$_] -eq $ezkey }    
        }
        
    } #foreach user
    
    Stop-Transcript
    exit

} # if response eq 3

   #GUI time! create form and listbox
   Add-Type -AssemblyName System.Windows.Forms
   Add-Type -AssemblyName System.Drawing

   $form = New-Object System.Windows.Forms.Form
   $form.Text = 'Dave Loves List Boxes'
   $form.Size = New-Object System.Drawing.Size(385,320)
   $form.StartPosition = 'CenterScreen'

   $OKButton = New-Object System.Windows.Forms.Button
   $OKButton.Location = New-Object System.Drawing.Point(10,250)
   $OKButton.Size = New-Object System.Drawing.Size(75,23)
   $OKButton.Text = 'OK'
   $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
   $form.AcceptButton = $OKButton
   $form.Controls.Add($OKButton)

   $CancelButton = New-Object System.Windows.Forms.Button
   $CancelButton.Location = New-Object System.Drawing.Point(85,250) #WL add 75
   $CancelButton.Size = New-Object System.Drawing.Size(75,23)
   $CancelButton.Text = 'Cancel'
   $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
   $form.CancelButton = $CancelButton
   $form.Controls.Add($CancelButton)

   $label = New-Object System.Windows.Forms.Label
   $label.Location = New-Object System.Drawing.Point(10,20)
   $label.Size = New-Object System.Drawing.Size(280,20)
   $label.Text = 'Please select from the list below:'
   $form.Controls.Add($label)

   $listBox = New-Object System.Windows.Forms.Listbox
   $listBox.Location = New-Object System.Drawing.Point(10,40)
   $listBox.Size = New-Object System.Drawing.Size(350,50)
   $listBox.SelectionMode = 'MultiExtended'

   #load sorted daveDirTemplateRoles keys into listbox
   $bob=$daveDirTemplateRoles.Keys | sort-object
   
   foreach ($thing in $bob) {
      [void] $listBox.Items.Add($thing)
   }

   $listBox.Height = 200
   $form.Controls.Add($listBox)
   $form.Topmost = $true

   $daveform = $form.ShowDialog()

   if ($daveform -eq [System.Windows.Forms.DialogResult]::OK) {

      foreach ($user in $bunchofusers) {

         foreach ($davekey in $listBox.SelectedItems){
	
	        if ($response -eq 1) {
		        $PrincipalId = Get-Mguser -UserID $user
   		        New-MgRoleManagementDirectoryRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $daveDirTemplateRoles[$davekey] -PrincipalId $PrincipalId.Id
	        
            } # if response eq 1

            if ($response -eq 2) {
                $PrincipalId = Get-Mguser -UserID $user
       
		        $params = @{
			        Action = "AdminAssign"
			        PrincipalId = $PrincipalId.Id
			        RoleDefinitionId = $daveDirTemplateRoles[$davekey]
			        DirectoryScopeId = "/"
			        ScheduleInfo = @{
	   		            StartDateTime = Get-Date #today
			            expiration = @{
			                type = "afterDateTime"
			                endDateTime = (Get-Date).AddDays($days)
			            } # expiration
    		        } # scheduleinfo
		        } # params

		        New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params

    	    } # if response eq 2
          
         } # foreach key
      } # foreach user
   } # if result eq ok
} # roles

default {

################################## default help

write-output "`nVERSION: v2.11`nUSAGE:   otto.ps1 -do [options]

OPTIONS:
	signins
	users
	licenses
	roles
"
exit

}

} #end switch do   

################################## the end!

#Stop-Transcript