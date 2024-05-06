#!/bin/bash

#login into cf cli
# Needs yq cli

# This will move ldap_users from manager to auditor

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

for org in $orgs; do
  org_name=$(echo $org | cut -d ":" -f 1)
  org_guid=$(echo $org | cut -d ":" -f 2)
  if [[ $org_name == "system" ]] || [[ $org_name == "credhub-service-broker-org" ]] || [[ $org_name == "p-spring-cloud-services" ]]
  then
      continue
  fi

  if [[ $(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-manager".ldap_users | length') > 0 ]]; then
    org_ldap_users=$(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-manager".ldap_users.[]')

    for org_ldap_user in $org_ldap_users; do
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            yq -i 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
            yq -i '."org-auditor".ldap_users += ['"\"$org_ldap_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            yq -iy 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
            yq -iy '."org-auditor".ldap_users += ['"\"$org_ldap_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        fi
    done
    remove_dup_org_users=$(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-auditor".ldap_users | unique' | yq .[])
    yq -i 'del(."org-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    for remove_dup_org_user in $remove_dup_org_users; do
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            yq -i '."org-auditor".ldap_users += ['"\"$remove_dup_org_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            yq -iy '."org-auditor".ldap_users += ['"\"$remove_dup_org_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        fi
    done
  fi
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

    if [[ $(cat $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml | yq -r '."space-manager".ldap_users | length') > 0 ]]; then
      space_ldap_users=$(cat $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml | yq -r '."space-manager".ldap_users.[]')

      for space_ldap_user in $space_ldap_users; do
          if [[ "$OSTYPE" == "linux-gnu"* ]]; then
              yq -i 'del(."space-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
              yq -i '."space-auditor".ldap_users += ['"\"$space_ldap_user\""']'  $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
          elif [[ "$OSTYPE" == "darwin"* ]]; then
              yq -iy 'del(."space-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
              yq  -iy '."space-auditor".ldap_users += ['"\"$space_ldap_user\""']' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
          fi
      done
      remove_dup_space_users=$(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-auditor".ldap_users | unique' | yq .[])
      yq -i 'del(."org-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
      for remove_dup_space_user in $remove_dup_space_users; do
          if [[ "$OSTYPE" == "linux-gnu"* ]]; then
              yq -i '."org-auditor".ldap_users += ['"\"$remove_dup_space_user\""']'  $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
          elif [[ "$OSTYPE" == "darwin"* ]]; then
              yq -iy '."org-auditor".ldap_users += ['"\"$remove_dup_space_user\""']'  $Path_To_Config_Dir/config/$org_name/$space_name/spaceConfig.yml
          fi
      done
    fi
  done
done
