## See External Applications for information on registering your application: https://docs.uipath.com/automation-cloud/docs/about-external-applications

$configPath = "config.json";


#######################################################################################################################################################################
#######################################################################################################################################################################
#######################################################################################################################################################################
#######################################################################################################################################################################
#######################################################################################################################################################################


#######
## Env Params
$config = Get-Content -Raw -Path $configPath | ConvertFrom-Json

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
		foreach($member in $currentGroup.members){
			$memberString += "`n- " + $member.DisplayName # + " (" + $member.identifier + ") "
			$memberCount++;
		}
		
		## Output summary
		$currentGroup.name + ": " + $memberCount
		$memberString
		
		
	}