## Re-generate the group summary and recent users files
Invoke-Expression -Command "./get-group-summary.ps1"
Invoke-Expression -Command "./get-recent-users.ps1"
## Get data paths
$groupsListPath = "exportFiles/licenseBuddyExport-groups.json"
$usersListPath = "exportFiles/licenseBuddyExport-users.json"

#### - Get Groups list with members
$groupsList = Get-Content -Path $groupsListPath | ConvertFrom-Json
#### - Get list of users with activity range
$usersList = Get-Content -Path $usersListPath | ConvertFrom-Json

#$groupsList
#$usersList

$inactiveUsers = @()
#### - build list of any users who meet criteria (no activity, other flags)
foreach($group in $groupsList){
	foreach($user in $group.members){
		if($usersList.$($user.UserEmail)){
			## User is found
			$group | Add-Member -MemberType NoteProperty -Name 'earliestDate' -Value $usersList.$($user.UserEmail).earliestDate
			$group | Add-Member -MemberType NoteProperty -Name 'latestDate' -Value $usersList.$($user.UserEmail).latestDate
		} else {
			## Add to not found list
			$user | Add-Member -MemberType NoteProperty -Name 'groupName' -Value $group.GroupName
			$inactiveUsers += $user
		}
	}
}
#$groupsList | ConvertTo-Json
$inactiveUsers | ConvertTo-Json


