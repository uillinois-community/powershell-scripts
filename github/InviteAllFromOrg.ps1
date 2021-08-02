function run {

  ##Set-GitHubAuthentication -SessionOnly
  
  $source_org = Read-Host "Organization Name to use to create invitee list "
  $target_org = Read-Host "Organization Name to send out invites "


  ## step 1: get the users in source org, and each team name they're on in source org
  $source_mapping = Get-GitHubOrg-UserInfos -GitHubOrgName $soruce_org

  # step 2: get a list of existing users already present in target org, filter out source list so 
  #   we don't re-add those people (TODO - maybe it so that they get added to groups if need be)

  $target_org_members = Get-GitHubOrganizationMember -OrganizationName $target_org | Select -ExpandProperty login
  $need_to_invite = $source_mapping.keys | where { -not ($target_org_members -contains $_) }

  # step 4: loop over still not present people, invite them using the proper tem ids
  foreach( $invite_login in $need_to_invite ) {
    $user_team_ids = $source_mapping[ $invite_login ] | Where { $team_id_lookup.ContainsKey( $_ )  } | %{ $team_id_lookup[ $_ ] }

    
   # manually adding jason in 
   $hashBody = @{
 #   'invitee_id' = $inv
#    'team_ids'  = ,4662866
   }

   $params = @{
     'Method' = 'Post'
     'UriFragment' =  "orgs/uiuclib-repo-archive/invitations" 
     'Body' = (ConvertTo-Json -InputObject $hashBody)  
   }

   #$invite_results = Invoke-GHRestMethod @params


   Write-Output "Would request to invite user $invite_login to $target_org with $user_team_ids "

    
  } 
}

function Get-GitHubOrg-UserInfos {

  param(
   [Parameter(Mandatory=$true)]
   $GitHubOrgName 
  )


  $filter_out_teams = ,"Core"

  $source_org_members = Get-GitHubOrganizationMember -OrganizationName $GitHubOrgName
  $teams = Get-GitHubTeam -OrganizationName $GitHubOrgName
  $member_is_part_of = @{}

  foreach($team in ( $teams | where { -not ($filter_out_teams -contains $_.name) } ) ) { 
    $team_members = Get-GitHubTeamMember -Organization $source_org -TeamName $team.name
   
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

  return $member_is_part_of
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

  





