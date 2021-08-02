# the teams stuff is extra sauce that we should probably ask about....

#$source_org = Read-Host "Organization Name to use to create invitee list "
#$target_org = Read-Host "Organization Name to send out invites "

#Set-GitHubAuthentication -SessionOnly

# step 1: get the users in source org, and each team name they're on in source org





# step 2: get a list of existing users already present in target org, filter out source list so 
#   we don't re-add those people (TODO - maybe it so that they get added to groups if need be)
# step 3: map the used teams in source to target org, warn if not present and remove/ignore those later
# step 4: loop over still not present people, invite them using the proper tem ids



#$target_org_members = Get-GitHubOrganizationMember -OrganizationName $target_org | Select -ExpandProperty login
#$need_to_invite = $source_org_members | where { -not ($already_present -contains $_.login) }

#Write-Output $need_to_invite

#foreach( $invite in $need_to_invite ) {
    
    # so... invitations is not yet implemented in module...
    # but might be able to reverse-engineer or partiall implement
    # by seeing other code and adding https://docs.github.com/en/rest/reference/orgs#create-an-organization-invitation
    #
    #

#    $login = $invite.login

#    Write-Output "Invites not yet implemented, but would try something like ${invite.login}"
#}


#function Get-Team-Name-And-Ids {
#}


function Get-GitHubOrg-UserLogins-TeamNames {

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

