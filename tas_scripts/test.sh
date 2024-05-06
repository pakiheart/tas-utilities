#!/bin/bash

#login into cf cli
# Needs yq cli
Path_To_Config_Dir=/Users/raltaf/workspace/TAS/tas-cf-mgmt
org_name=org1
  if [[ $(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-manager".ldap_users | length') > 0 ]]; then
    org_ldap_users=$(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-manager".ldap_users.[]')

    for org_ldap_user in $org_ldap_users; do
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            yq -i 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
            yq -i '."org-auditor".ldap_users += ['"\"$org_ldap_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            yq -i 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
            yq -i '."org-auditor".ldap_users += ['"\"$org_ldap_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        fi
    done
    dup_users=$(cat $Path_To_Config_Dir/config/$org_name/orgConfig.yml | yq -r '."org-auditor".ldap_users | unique' | yq .[])
    echo "******" $dup_users
    yq -i 'del(."org-auditor".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
    for dup_user in $dup_users; do
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            yq -i 'del(."org-manager".ldap_users)' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
            yq -i '."org-auditor".ldap_users += ['"\"$org_ldap_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            #yq -i '."org-auditor" += {ldap_users: []}' $Path_To_Config_Dir/config/$org_name/orgConfig.yml
            echo "-----------" $dup_user
            yq -i '."org-auditor".ldap_users += ['"\"$dup_user\""']'  $Path_To_Config_Dir/config/$org_name/orgConfig.yml
        fi
    done

  fi

