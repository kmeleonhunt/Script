#Import-Module Microsoft.Graph.Identity.SignIns

#Navigate the scope list available
$ScopesList = Find-MgGraphPermission | ? { $_.Name -like "*Policy*" } | Select-Object Name, Description

$Scopes=@('Policy.ReadWrite.ConditionalAccess')
#Connect-MgGraph services with correct scopes
Connect-MgGraph -Scopes $Scopes

Get-mgcontext

#####################################################

#Get all Conditional Access policies
$PoliciesList = Get-MgIdentityConditionalAccessPolicy

$PoliciesData = @()
#List all the policies display name and Id's
Foreach ($policy in $PoliciesList){

    $resultObject = [PSCustomObject]@{
        DisplayName   = $($policy.DisplayName)
        ID            = $($policy.id)
        Conditions    = $($policy.Conditions)
        Controls      = $($policy.GrantControls) 
        }

$PoliciesData += $resultObject

    }

$MFAAdmin = $PoliciesData | ? {$_.DisplayName -like "*Token*"} | Select 


######################
#Scan all the policies and convert the result to JSON

$DetailedPolicy = @()
Foreach ($i in $PoliciesData.ID){
    Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $i | ConvertTo-Json 
     $resultObject = [PSCustomObject]@{
        DisplayName   = $($policy.DisplayName)
        ID            = $($policy.id)
        Conditions    = $($policy.Conditions)
        Controls      = $($policy.GrantControls) 
        }

}

#############################
# Enforce MFA for All Users #      
#############################
$params = @{
	displayName = "Standard - Enforce MFA for All users"
	state = "disabled"
	conditions = @{
		clientAppTypes = @(
            "browser"
            "mobileAppsAndDesktopClients"
		)
		applications = @{
			includeApplications = @(
				"All"
			)
		}
		users = @{
			includeUsers = @(
				"All"
			)
			excludeUsers = @(
				#Yous should add the Global Administrator account here and service accounts, hope you have made security groups already defined
				"GuestsOrExternalUsers"
                "Global_Admin"
                "Service_Accounts"

			)
			#includeGroups = @(
                
			#)
			#excludeGroups = @(
            ##Here you can exlude security groups
			#)
			#includeRoles = @(
				##Not sure if we can add roles as Display Name or we need Id
			#)
			#excludeRoles = @(
			#)
		}
		platforms = @{
			includePlatforms = @(
				"All"
			)
			#excludePlatforms = @(
				#"iOS"
				#"windowsPhone"
			#)
		}
		locations = @{
			includeLocations = @(
				"All"
			)
			#excludeLocations = @(
				#"00000000-0000-0000-0000-000000000000"
				#"d2136c9c-b049-47ae-b9cf-316e04ef7198"
			#)
		}
	}
	grantControls = @{
		operator = "OR"
		builtInControls = @(
			"mfa"
			#"compliantDevice"
			#"domainJoinedDevice"
			#"approvedApplication"
			#"compliantApplication"
		)
		#customAuthenticationFactors = @(
		#)
		#termsOfUse = @(
			#"ce580154-086a-40fd-91df-8a60abac81a0"
			#"7f29d675-caff-43e1-8a53-1b8516ed2075"
		#)
	}
	#sessionControls = @{
		#applicationEnforcedRestrictions = $null
		persistentBrowser = $null
		#cloudAppSecurity = @{
			#cloudAppSecurityType = "blockDownloads"
			#isEnabled = $true
		#}
		signInFrequency = @{
			value = 7
			type = "days"
			isEnabled = $true
		}
	}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

###############################
# Block legacy authentication #      
###############################
$params = @{
	displayName = "Block legacy authentication 2"
	state = "disabled"
	conditions = @{
		clientAppTypes = @(
            "Exchange ActiveSync clients"
            "Other clients"
		)
		applications = @{
			includeApplications = @(
				"All"
			)
		}
		users = @{
			includeUsers = @(
				"All"
			)
			excludeUsers = @(
				#Yous should add the Global Administrator account here and service accounts, hope you have made security groups already defined
				"GuestsOrExternalUsers"
			)
			#includeGroups = @(
                
			#)
			#excludeGroups = @(
            ##Here you can exlude security groups
			#)
			#includeRoles = @(
				##Not sure if we can add roles as Display Name or we need Id
			#)
			#excludeRoles = @(
			#)
		}
		#platforms = @{
			#includePlatforms = @(
				#"All"
			#)
			#excludePlatforms = @(
				#"iOS"
				#"windowsPhone"
			#)
		#}
		#locations = @{
			#includeLocations = @(
			#	"All"
			#)
			#excludeLocations = @(
				#"00000000-0000-0000-0000-000000000000"
				#"d2136c9c-b049-47ae-b9cf-316e04ef7198"
			#)
		#}
	}
	grantControls = @{
		#operator = "OR"
		builtInControls = @(
			"Block access"
			#"compliantDevice"
			#"domainJoinedDevice"
			#"approvedApplication"
			#"compliantApplication"
		)
		#customAuthenticationFactors = @(
		#)
		#termsOfUse = @(
			#"ce580154-086a-40fd-91df-8a60abac81a0"
			#"7f29d675-caff-43e1-8a53-1b8516ed2075"
		#)
	}
	#sessionControls = @{
		#applicationEnforcedRestrictions = $null
		#persistentBrowser = $null
		#cloudAppSecurity = @{
			#cloudAppSecurityType = "blockDownloads"
			#isEnabled = $true
		#}
		#signInFrequency = @{
			#value = 7
			#type = "days"
			#isEnabled = $true
		#}
	}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

##########################
# Require MFA For Admins #
##########################

$params = @{
	displayName = "Require MFA For Admins"
	state = "disabled"
	conditions = @{
		#clientAppTypes = @(
            #"browser"
           # "mobileAppsAndDesktopClients"
		#)
		applications = @{
			includeApplications = @(
				"All"
			)
		}
		users = @{
			#includeUsers = @(
				#"All"
			#)
			excludeUsers = @(
				#You should add the Global Administrator account here and service accounts, hope you have made security groups already defined

			)
			#includeGroups = @(
                
			#)
			#excludeGroups = @(
            ##Here you can exlude security groups
            #"GuestsOrExternalUsers"
            #"Global_Admins"
            #"Service_Accounts"
			#)
			includeRoles = @(
				"9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
                "c4e39bd9-1100-46d3-8c65-fb160da0071f"
                "b0f54661-2d74-4c50-afa3-1ec803f12efe"
                "158c047a-c907-4556-b7ef-446551a6b5f7"
                "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
                "29232cdf-9323-42fd-ade2-1d097af3e4de"
                "62e90394-69f5-4237-9190-012177145e10"
                "729827e3-9c14-49f7-bb1b-9608f156bbb8"
                "966707d0-3269-4727-9be2-8c3a10f19b9d"
                "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
                "194ae4cb-b126-40b2-bd5b-6091b380977d"
                "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
                "fe930be7-5e62-47db-91af-98c3a49a38b1"
                "0526716b-113d-4c15-b2c8-68e3c22b9f80"
                "fdd7a751-b60b-444a-984c-02652fe8fa1c"
                "4d6ac14f-3453-41d0-bef9-a3e0c569773a"
                "2b745bdf-0803-4d80-aa65-822c4493daac"
                "11648597-926c-4cf3-9c36-bcebb0ba8dcc"
                "e8611ab8-c189-46e8-94e1-60213ab1f814"
                "f023fd81-a637-4b56-95fd-791ac0226033"
                "69091246-20e8-4a56-aa4d-066075b2a7a8"
			)
			#excludeRoles = @(
			#)
		}
		platforms = @{
			#includePlatforms = @(
			#	"All"
			#)
			#excludePlatforms = @(
				#"iOS"
				#"windowsPhone"
			#)
		}
		#locations = @{
			#includeLocations = @(
				#"All"
			#)
			#excludeLocations = @(
				#"00000000-0000-0000-0000-000000000000"
				#"d2136c9c-b049-47ae-b9cf-316e04ef7198"
			#)
		#}
	}
	grantControls = @{
		operator = "OR"
		builtInControls = @(
			"mfa"
			#"compliantDevice"
			#"domainJoinedDevice"
			#"approvedApplication"
			#"compliantApplication"
		)
		#customAuthenticationFactors = @(
		#)
		#termsOfUse = @(
			#"ce580154-086a-40fd-91df-8a60abac81a0"
			#"7f29d675-caff-43e1-8a53-1b8516ed2075"
		#)
	}
	#sessionControls = @{
		#applicationEnforcedRestrictions = $null
		persistentBrowser = $null
		#cloudAppSecurity = @{
			#cloudAppSecurityType = "blockDownloads"
			#isEnabled = $true
		#}
		#signInFrequency = @{
			#value = 7
			#type = "days"
			#isEnabled = $true
		}
	

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

###################################
# Disable Admin Token Persistence # WIP Seems like cannot select the correct options, research needed
###################################

$params = @{
	displayName = "Disable Admin Token Persistence TEST"
	state = "disabled"
	conditions = @{
		#clientAppTypes = @(
            #"browser"
            #"mobileAppsAndDesktopClients"
		#)
		applications = @{
			includeApplications = @(
				"All"
			)
		}
		users = @{
			#includeUsers = @(
				#"All"
			#)
			excludeUsers = @(
				#You should add the Global Administrator account here and service accounts, hope you have made security groups already defined

			)
			#includeGroups = @(
                
			#)
			#excludeGroups = @(
            ##Here you can exlude security groups
            #"GuestsOrExternalUsers"
                #"Global_Admins"
                #"Service_Accounts"
			#)
			includeRoles = @(
				"9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
                "c4e39bd9-1100-46d3-8c65-fb160da0071f"
                "b0f54661-2d74-4c50-afa3-1ec803f12efe"
                "158c047a-c907-4556-b7ef-446551a6b5f7"
                "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
                "29232cdf-9323-42fd-ade2-1d097af3e4de"
                "62e90394-69f5-4237-9190-012177145e10"
                "729827e3-9c14-49f7-bb1b-9608f156bbb8"
                "966707d0-3269-4727-9be2-8c3a10f19b9d"
                "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
                "194ae4cb-b126-40b2-bd5b-6091b380977d"
                "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
                "fe930be7-5e62-47db-91af-98c3a49a38b1"
                "0526716b-113d-4c15-b2c8-68e3c22b9f80"
                "fdd7a751-b60b-444a-984c-02652fe8fa1c"
                "4d6ac14f-3453-41d0-bef9-a3e0c569773a"
                "2b745bdf-0803-4d80-aa65-822c4493daac"
                "11648597-926c-4cf3-9c36-bcebb0ba8dcc"
                "e8611ab8-c189-46e8-94e1-60213ab1f814"
                "f023fd81-a637-4b56-95fd-791ac0226033"
                "69091246-20e8-4a56-aa4d-066075b2a7a8"
			)
			#excludeRoles = @(
			#)
		}
		platforms = @{
			#includePlatforms = @(
				#"All"
			#)
			#excludePlatforms = @(
				#"iOS"
				#"windowsPhone"
			#)
		}
		locations = @{
			includeLocations = @(
				"All"
			)
			#excludeLocations = @(
				#"00000000-0000-0000-0000-000000000000"
				#"d2136c9c-b049-47ae-b9cf-316e04ef7198"
			#)
		}
	}
	grantControls = @{
		#operator = "OR"
		#builtInControls = @(
			#"mfa"
			#"compliantDevice"
			#"domainJoinedDevice"
			#"approvedApplication"
			#"compliantApplication"
		#)
		#customAuthenticationFactors = @(
		#)
		#termsOfUse = @(
			#"ce580154-086a-40fd-91df-8a60abac81a0"
			#"7f29d675-caff-43e1-8a53-1b8516ed2075"
		#)
	}
	#sessionControls = @{
		#applicationEnforcedRestrictions = $null
		persistentBrowser = "Never Persistent"
		#cloudAppSecurity = @{
			#cloudAppSecurityType = "blockDownloads"
			#isEnabled = $true
		#}
		signInFrequency = @{
			value = 9
			type = "Hours"
			isEnabled = $true
		}
	}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params


                    #####-END-#####

################
#Example Full :#
################ 
$params = @{
	displayName = "Demo app for documentation"
	state = "disabled"
	conditions = @{
		#signInRiskLevels = @(
			#"high"
			#"medium"
		#)
		clientAppTypes = @(
            "All"
			#"mobileAppsAndDesktopClients"
			#"exchangeActiveSync"
			#"other"
		)
		applications = @{
			includeApplications = @(
				"All"
			)
			#excludeApplications = @(
				#"499b84ac-1321-427f-aa17-267ca6975798"
				#"00000007-0000-0000-c000-000000000000"
				#"de8bc8b5-d9f9-48b1-a8ad-b748da725064"
				#"00000012-0000-0000-c000-000000000000"
				#"797f4846-ba00-4fd7-ba43-dac1f8f63013"
				#"05a65629-4c1b-48c1-a78b-804c4abdd4af"
				#"7df0a125-d3be-4c96-aa54-591f83ff541c"
			#)
			#includeUserActions = @(
			#)
		}
		users = @{
			includeUsers = @(
				"All"
			)
			excludeUsers = @(
				#"124c5b6a-ffa5-483a-9b88-04c3fce5574a"
				"GuestsOrExternalUsers"
			)
			#includeGroups = @(
			#)
			#excludeGroups = @(
			#)
			#includeRoles = @(
				#"9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
				#"cf1c38e5-3621-4004-a7cb-879624dced7c"
				#"c4e39bd9-1100-46d3-8c65-fb160da0071f"
			#)
			#excludeRoles = @(
				#"b0f54661-2d74-4c50-afa3-1ec803f12efe"
			#)
		}
		platforms = @{
			includePlatforms = @(
				"all"
			)
			#excludePlatforms = @(
				#"iOS"
				#"windowsPhone"
			#)
		}
		locations = @{
			includeLocations = @(
				"All"
			)
			#excludeLocations = @(
				#"00000000-0000-0000-0000-000000000000"
				#"d2136c9c-b049-47ae-b9cf-316e04ef7198"
			#)
		}
	}
	grantControls = @{
		operator = "OR"
		builtInControls = @(
			"mfa"
			#"compliantDevice"
			#"domainJoinedDevice"
			#"approvedApplication"
			#"compliantApplication"
		)
		#customAuthenticationFactors = @(
		#)
		#termsOfUse = @(
			#"ce580154-086a-40fd-91df-8a60abac81a0"
			#"7f29d675-caff-43e1-8a53-1b8516ed2075"
		#)
	}
	sessionControls = @{
		applicationEnforcedRestrictions = $null
		persistentBrowser = $null
		#cloudAppSecurity = @{
			#cloudAppSecurityType = "blockDownloads"
			#isEnabled = $true
		#}
		signInFrequency = @{
			value = 4
			type = "hours"
			isEnabled = $true
		}
	}
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $params

  