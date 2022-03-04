## See External Applications for information on registering your application: https://docs.uipath.com/automation-cloud/docs/about-external-applications


#---------------------------------------------------------------------#################################################################################################
## Configuration

if(Test-Path 'powershell/exportFiles/'){
	#######################################################################################################################################################################
	#### OPTION 1     (of 2) #############################################################################################################################################
	#######################################################################################################################################################################
	#### Invoked via UiPath Workflow									  #################################################################################################
																		  #################################################################################################
	$config = $rawConfig | ConvertFrom-Json ## Invoking from workflow
	$outputFileName = 'powershell/exportFiles/licenseBuddyExport-users.json'

} else {
	#######################################################################################################################################################################
	#### OPTION 2   (of 2) ################################################################################################################################################
	#######################################################################################################################################################################
	#### Standalone Script												  #################################################################################################
																		  #################################################################################################
	$configPath = "config.json";
	$config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
	$outputFileName = 'exportFiles/licenseBuddyExport-users.json'

}



######################################################################################################----------------------------------------------------------------#

$folderId = "60616"
$outputFileName = 'exportFiles/licenseBuddyExport-users.json'
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
$headers += @{
	"X-UIPATH-OrganizationUnitId" = "$folderId"
}

## >>>>>>>>>>>>>>>>>>> ########################################################
##
## Get Robot Logs
##
## TODO: Tweak what exactly we're retrieving (date range) from RobotLogs
$logsUrl = $config.base_orch_url + "/" + $config.account_id + "/" + $config.tenant_name + "/orchestrator_/odata/RobotLogs"

$logsResponse = Invoke-WebRequest -Uri $logsUrl -Method GET -Headers $headers -ContentType application/json
$responseContent = $logsResponse.Content | ConvertFrom-Json

$logsList = $responseContent.value 

$logUsers = @{};

foreach($log in $logsList){
	$data = $log.RawMessage | ConvertFrom-Json	
		
	$userKey = $data.robotName.Split("-")[0]
	
	## IF user exists:
	if($logUsers.$($userKey)){
		## ~Modify existing
	
		if((get-date $data.timeStamp) -lt (get-date $logUsers.$($userKey).earliestDate)){
			## Update - because newtime is less than old time
			$logUsers.$($userKey).earliestDate = $data.timeStamp
		}
		if((get-date $data.timeStamp) -gt (get-date $logUsers.$($userKey).latestDate)){
			## Update - because newtime is less than old time
			$logUsers.$($userKey).latestDate = $data.timeStamp
		}
	
		## LogCount
		$logUsers.$($userKey).logCount++
	
		## ErrorCount
		if($data.level -eq "Error"){
			$logUsers.$($userKey).errorCount++
		}	
	
		#$data.timeStamp + ": " + $data.windowsIdentity + " - " + $data.message #### << DEBUG
		continue
	}	
	
	
	############################################
	### User has not been added; create as new
	############################################
	
	### If an error exists
	$errorCount = 0
	if($data.level -eq "Error"){
		
		$errorCount=1
	}
		
	## Add user entry
	$logUsers.Add($userKey, [PSCustomObject]@{
		windowsIdentity = $data.windowsIdentity
		robotName = $data.robotName
		earliestDate = $data.timeStamp
		latestDate = $data.timeStamp
		logCount = 1
		errorCount = $errorCount
	}) 
}

$logUsersJSON = $logUsers | ConvertTo-Json
$logUsersJSON | Set-Content -Path $outputFileName

#$logUsersJSON 

return