# the teams stuff is extra sauce that we should probably ask about....

$source_org = Read-Host "Organization Name to use to create invitee list "
$target_org = Read-Host "Organization Name to send out invites "

$filter_out_teams = ,"Core"

#Set-GitHubAuthentication -SessionOnly
$source_org_members = Get-GitHubOrganizationMember -OrganizationName $source_org
$teams = Get-GitHubTeam -OrganizationName $source_org
$member_is_part_of = @{}

foreach($team in ( $teams | where { -not ($filter_out_teams -contains $_.name) } ) ) { 
  $team_members = Get-GitHubTeamMember -Organization $source_org -TeamName $team.name
  
  foreach( $team_member in $team_members ) {
    if( $member_is_part_of.ContainsKey( $team_member.login ) ){
       # this member has already been added to at least one team, so we just need to 
       # add to the array at this place....
      $member_is_part_of[$team_member.login] += $team.id
     }
     else {
      $member_is_part_of[$team_member.login] = ,$team.id
     }
  }
}

Write-Output $member_is_part_of




# $already_present = $source_org_members = Get-GitHubOrganizationMember -OrganizationName $target_org | Select -ExpandProperty login
#
# $need_to_invite = $source_org_members | where { -not ($already_present -contains $_.login) }
#
# foreach( $invite in $need_to_invite ) {
#    
#    # so... invitations is not yet implemented in module...
#    # but might be able to reverse-engineer or partiall implement
#    # by seeing other code and adding https://docs.github.com/en/rest/reference/orgs#create-an-organization-invitation
#    #
#    #
#    Write-Output $"Invites not yet implemented, but would try somethign like ${invite.login}"
#}



