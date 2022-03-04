## See External Applications for information on registering your application: https://docs.uipath.com/automation-cloud/docs/about-external-applications

#######################################################################################################################################################################
#######################################################################################################################################################################
#######################################################################################################################################################################
#######################################################################################################################################################################
#######################################################################################################################################################################

###############################################################################
#######
## Env Params

if(Test-Path 'powershell/exportFiles/'){
	## run from workflow
	$config = $rawConfig | ConvertFrom-Json ## Invoking from workflow
	$outputFileName = 'powershell/exportFiles/licenseBuddyExport-groups.json'
} else {
	$configPath = "config.json";
	$config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
	$outputFileName = 'exportFiles/licenseBuddyExport-groups.json'
}

#### Use for standalone script
#$configPath = "config.json";
#$config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
#$outputFileName = 'exportFiles/licenseBuddyExport-groups.json'

#if(!$config){
#### Use if invoked from workflow
#$config = $rawConfig | ConvertFrom-Json ## Invoking from workflow
#$outputFileName = 'powershell/exportFiles/licenseBuddyExport-groups.json'
#}

###############################################################################
###############################################################################
###############################################################################

$partitionGlobalId = $config.partition_global_id
$token_url = $config.token_url

## >>>>>>>>>>>>>>>>>>> ########################################################
##
## Get Access Token
##
$accessTokenParams = @{
	grant_type='client_credentials';
	client_id=$config.client_id;
	client_secret=$config.client_secret;
	client_scopes=$config.client_scopes;
}
$tokenResponse = Invoke-WebRequest -Uri $token_url -Method POST -Body $accessTokenParams -ContentType application/x-www-form-urlencoded -UseBasicParsing
$temp = $tokenResponse.Content | ConvertFrom-Json
$access_token = $temp.access_token

$headers = @{
	"Authorization" = "Bearer $access_token"
	"ContentType" = "application/json"
	"Accept" = "application/json"
}



## >>>>>>>>>>>>>>>>>>> ########################################################
##
## Get Group List
##

$grouplistUrl = $config.base_orch_url + "/identity_/api/Group/" + $partitionGlobalId 
$grouplistResponse = Invoke-WebRequest -Uri $grouplistUrl -Method GET -Headers $headers -ContentType application/json
$groupList = $grouplistResponse.Content | ConvertFrom-Json

$groups = @();


foreach($group in $groupList){
	
	## >>>>>>>>>>>>>>>>>>> ########################################################
	##
	## Get Each Group
	##
	$groupUrl = $config.base_orch_url + "/identity_/api/Group/" + $partitionGlobalId + $group.id
	$groupResponse = Invoke-WebRequest -Uri $groupUrl -Method GET -Headers $headers -ContentType application/json
	$currentGroup = $groupResponse.Content | ConvertFrom-Json
	
	$memberCount = 0;
	$memberString = "";
	$userList = @();
	foreach($member in $currentGroup.members){
		
		
		## >>>>>>>>>>>>>>>>>>> ########################################################
		##
		## Get User Info
		##

		$userUrl = $config.base_orch_url + "/" + $config.account_id + "/identity_/api/User/" + $member.identifier
		# https://cloud.uipath.com/uipatorveimm/portal_/api/identity/UserPartition/licenses?partitionGlobalId=d6126e53-a8fc-4c9b-a0e7-00ff9b9ae8e4&top=25&skip=0
		# https://cloud.uipath.com/uipatorveimm/identity_/api/User/{userId}
		# /identity_/api/User/{userId}
#		$userResponse = Invoke-WebRequest -Uri $userUrl -Method GET -Headers $headers -ContentType application/json
#		$groupAllocationsResponse
#		$currentUser = $userResponse.Content | ConvertFrom-Json
				
		$userList += [PSCustomObject]@{
			UserName = $member.DisplayName
			UserEmail = $member.name
			UserId = $member.identifier
		}
		$memberString += "`n- " + $member.DisplayName # + " (" + $member.identifier + ") "
		$memberCount++;
	}
		
	## Output summary
	#$currentGroup.name + ": " + $memberCount #| Add-Content -Path .\CopyToFile.txt
	#$memberString #| Add-Content -Path .\CopyToFile.txt
	
	$groups += [PSCustomObject]@{
		GroupName 		= $currentGroup.name
		GroupId			= $group.id
		MemberCount 	= $memberCount
		Members			= $userList
	}
	
}
$jsonOutput = $groups | ConvertTo-Json -Depth 4
$jsonOutput | Set-Content -Path $outputFileName



#return $groups