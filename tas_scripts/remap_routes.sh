#!/bin/bash
#login into cf cli
#Needs yq cli

# This will remove ldap_users from each org and space config
# and then add ldap_groups to each org and space
# ldap group naming convention is OrgName-Role and OrgName-SpaceName-Role
# It also writes out all groupnames to a text file

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Usage: " $0 "domain_name"
    exit 1
fi

Domain_Name=$1

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
  echo "Org: " $org_name

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
    apps=$(cf curl /v3/apps?space_guids=$space_guid | jq -r '.resources[] | .name + ":" + .guid')
    for app in $apps; do
      app_name=$(echo $app | cut -d ":" -f 1)
      app_guid=$(echo $app | cut -d ":" -f 2)
      hosts=$(cf curl /v3/apps/$app_guid/routes | jq -r '.resources[] | .host + ":" + .path')
      cf target -o $org_name -s $space_name
      for host in $hosts; do
        host=$(echo $space | cut -d ":" -f 1)
        path=$(echo $space | cut -d ":" -f 2)

        echo $app_name
        echo $Domain_Name
        echo $host
        echo $path
        cf unmap-route $app_name $Domain_Name --hostname $host --path $path
        cf map-route $app_name $Domain_Name --hostname $host --path $path

      done

    done
  done
done
