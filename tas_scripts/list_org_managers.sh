 #!/bin/bash
#login into cf cli


#IFS=$' '
total_pages=$(cf curl /v3/organizations | jq -r .pagination.total_pages)

orgs=""
for page in $(seq 1 $total_pages); do
    orgs+=$(cf curl /v3/organizations/?page=$page  | jq -r '.resources[] | .name + ":" + .guid')
    if [[ $page == $total_pages ]]; then
      continue
    fi
    orgs+="\n"
done

IFS=$'\n'
echo 'OrgName, OrgGuid, OrgManagers' > orgManagers.csv

for org in $orgs; do
  org_name=$(echo $org | cut -d ":" -f 1)
  org_guid=$(echo $org | cut -d ":" -f 2)
  orgManagers=$(cf curl /v2/organizations/$org_guid/managers | jq -r .resources[].entity.username)
  echo $org_name, $org_guid, $orgManagers >> orgManagers.csv
done
