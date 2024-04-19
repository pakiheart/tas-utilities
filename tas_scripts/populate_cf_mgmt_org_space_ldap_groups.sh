#!/bin/bash
#login into cf cli
# Needs yq cli

# This will remove ldap_users from each org and space config
# and then add ldap_groups to each org and space
# ldap group naming convention is OrgName-Role and OrgName-SpaceName-Role
# It also writes out all groupnames to a text file

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Usage: " $0 "/path/to/config/dir(/mydir/cf-mgmt)"
    exit 1
fi

Path_To_Config_Dir=$1

total_pages=$(cf curl /v3/organizations | jq -r .pagination.total_pages)
IFS=$'\n'

orgs=""
for page in $(seq 1 $total_pages); do
    orgs+=$(cf curl /v3/organizations/?page=$page  | jq -r '.resources[] | .name + ":" + .guid')
    if [[ $page == $total_pages ]]; then
      continue
    fi
    orgs+=$'\n'
    
done

echo "LdapGroupNames" > ldapGroupNames.txt
echo "***************************" >> ldapGroupNames.txt
# update all org ldap groups
for org in $orgs; do
  org_name=$(echo $org | cut -d ":" -f 1)
  org_guid=$(echo $org | cut -d ":" -f 2)
  if [[ $org_name == "system" ]] || [[ $org_name == "credhub-service-broker-org" ]] || [[ $org_name == "p-spring-cloud-services" ]]
  then
      continue
  fi
  echo "Org: " $org_name
  echo $org_name-OrgMgr >> ldapGroupNames.txt
  echo $org_name-OrgAud >> ldapGroupNames.txt

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    yq -i 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -i '.org-manager.ldap_users=[]' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -i '."org-manager".ldap_groups += ['"\"$org_name-OrgMgr\""']' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -i 'del(."org-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -i '.org-auditor.ldap_users=[]' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -i '."org-auditor".ldap_groups += ['"\"$org_name-OrgAud\""']' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
  elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac OSX
    yq -iy 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -iy '."org-manager" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -iy '."org-manager".ldap_groups += ['"\"$org_name-OrgMgr\""']' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -iy 'del(."org-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -iy '."org-auditor" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    yq -iy '."org-auditor".ldap_groups += ['"\"$org_name-OrgAud\""']' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
  fi

  #update all spaces ldap groups
  total_pages=$(cf curl '/v2/organizations/'"$org_guid"'/spaces' | jq -r .total_pages)

  spaces=""
  for page in $(seq 1 $total_pages); do
    spaces+=$(cf curl '/v2/organizations/'"$org_guid"'/spaces?page='$page  | jq -r '.resources[] | .metadata.guid + ":" + .entity.name')
  
    if [[ $page == $total_pages ]]; then
      continue
    fi
    spaces+=$'\n'
  done

  for space in $spaces; do
    space_guid=$(echo $space | cut -d ":" -f 1)
    space_name=$(echo $space | cut -d ":" -f 2)
    echo "  Space: " $space_name
    echo $org_name-$space_name-SpaceMgr >> ldapGroupNames.txt
    echo $org_name-$space_name-SpaceDev >> ldapGroupNames.txt
    echo $org_name-$space_name-SpaceAud >> ldapGroupNames.txt
    echo $org_name-$space_name-SpaceSupp >> ldapGroupNames.txt
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then 

      yq -i 'del(."space-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '.space-manager.ldap_users=[]' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '."space-manager".ldap_groups += ['"\"$org_name-$space_name-SpaceMgr\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i 'del(."space-developer".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '.space-developer.ldap_users=[]' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '."space-developer".ldap_groups += ['"\"$org_name-$space_name-SpaceDev\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i 'del(."space-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '.space-auditor.ldap_users=[]' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '."space-auditor".ldap_groups += ['"\"$org_name-$space_name-SpaceAud\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i 'del(."space-supporter".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '.space-supporter.ldap_users=[]' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -i '."space-supporter".ldap_groups += ['"\"$org_name-$space_name-SpaceSupp\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
    elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
      yq -iy 'del(."space-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-manager" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-manager".ldap_groups += ['"\"$org_name-$space_name-SpaceMgr\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy 'del(."space-developer".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-developer" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-developer".ldap_groups += ['"\"$org_name-$space_name-SpaceDev\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy 'del(."space-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-auditor" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-auditor".ldap_groups += ['"\"$org_name-$space_name-SpaceAud\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy 'del(."space-supporter".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-supporter" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      yq -iy '."space-supporter".ldap_groups += ['"\"$org_name-$space_name-SpaceSupp\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml

    fi
  done
done
