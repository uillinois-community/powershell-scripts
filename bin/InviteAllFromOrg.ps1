function run {

  ##Set-GitHubAuthentication -SessionOnly

  param(
   [string]$GitHubSourceOrgName,
   [string]$GitHubTargetOrgName,
   [switch]$DryRun = $false,
   [int]$SecondsPauseBetweenRequests = 1,
   [string[]]$SkipLogins = @()
    
  )


  if( -not $PSBoundParameters.ContainsKey("GitHubSourceOrgName") ) {
    $GitHubSourceOrgName = Read-Host "Organization Name to use to create invitee list "
  }

  if( -not $PSBoundParameters.ContainsKey("GitHubTargetOrgName") ) {
    $GitHubTargetOrgName = Read-Host "Organization Name to send out invites "
  }

  $target_org_team_ids = Get-GitHubOrg-TeamName-To-TeamId -GitHubOrgName $GitHubTargetOrgName

  ## step 1: get the users in source org, and each team name they're on in source org
  $source_users = Get-GitHubOrg-UserInfos -GitHubOrgName $GitHubSourceOrgName

  # step 2: get a list of existing users already present in target org, filter out source list so 
  #   we don't re-add those people (TODO - maybe it so that they get added to groups if need be)

  $GitHubTargetOrgName_login = Get-GitHubOrganizationMember -OrganizationName $GitHubTargetOrgName | Select -ExpandProperty login
  $need_to_invite = $source_users  | where { -not ($GitHubTargetOrgName_login -contains $_.login) } | where { -not ($SkipLogins -contains $_.login) }

  # step 4: loop over still not present people, invite them using the proper tem ids
  foreach( $invitee in $need_to_invite ) {

   # manually adding jason in 
   $hashBody = @{
     'invitee_id' = $invitee.id
   }

   if( [bool]($invitee.PSobject.Properties.name -eq "TeamNames") ) {
     # TODO: Experiment with if team mapping not found...should at least warn
     
     # tried to be clever wtth a %{}, but it's not working well when there's just one element
     
     $hashBody['team_ids'] = @($invitee.TeamNames | %{ $target_org_team_ids[ $_ ] })

   }

   $body = (ConvertTo-Json -InputObject $hashBody)

   $params = @{
     'Method' = 'Post'
     'UriFragment' =  "orgs/uiuclib-repo-archive/invitations" 
     'Body' =  $body  
   }

   if( -not $DryRun ) {
     try {
       $invite_results = Invoke-GHRestMethod @params
       Write-Output $invite_results
     }
     catch {
      Write-Output "Request failed on $($invitee.login): $PSItem" 
     }
   }
   else {
     Write-Output "Would request to invite user $( $invitee.login)  ($($invitee.id)) with..."
     Write-Output $params["Body"] 
   }
   Start-Sleep -s $SecondsPauseBetweenRequests
    
  } 
}

function Get-GitHubOrg-UserInfos {

  param(
   [Parameter(Mandatory=$true)]
   $GitHubOrgName 
  )

  $users = @()


  #TODO: make this a parameter
  $filter_out_teams = ,"Core"


  $member_is_part_of = @{}

  $GitHubSourceOrgName_members = Get-GitHubOrganizationMember -OrganizationName $GitHubOrgName
  $teams = Get-GitHubTeam -OrganizationName $GitHubOrgName

  foreach($team in ( $teams | where { -not ($filter_out_teams -contains $_.name) } ) ) { 
    $team_members = Get-GitHubTeamMember -Organization $GitHubSourceOrgName -TeamName $team.name
   
    foreach( $team_member in $team_members ) {
      if( $member_is_part_of.ContainsKey( $team_member.login ) ){
         # this member has already been added to at least one team, so we just need to 
         # add to the array at this place....
        $member_is_part_of[$team_member.login] += $team.name
       }
       else {
        $member_is_part_of[$team_member.login] = ,$team.name
       }
    }
  }

  $GitHubSourceOrgName_members | %{
    if( $member_is_part_of.ContainsKey( $_.login) ) {
      Add-Member -InputObject $_ -NotePropertyName TeamNames -NotePropertyValue $member_is_part_of[ $_.login ]
    }
  }



  return $GitHubSourceOrgName_members
}


# we could be in trouble if there's two teams w/ same name but different ids...
# should probably check and error 
function Get-GitHubOrg-TeamName-To-TeamId {

  param(
   [Parameter(Mandatory=$true)]
   $GitHubOrgName 
  )

  $team_ids = @{} 

  $teams = Get-GitHubTeam -OrganizationName $GitHubOrgName

  foreach( $team in $teams ) { 
    if( $team_ids.ContainsKey( $team.name ) ) {
      throw "There was more than one ${team.name} in ${GitHubOrgName}"
    }
    else {
      $team_ids[$team.name] = $team.id
    }
  }

  return $team_ids
}

  





