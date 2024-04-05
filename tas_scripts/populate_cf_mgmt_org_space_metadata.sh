 #!/bin/bash
#login into cf cli
set -e


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


# update all org metadata
for org in $orgs; do
    org_name=$(echo $org | cut -d ":" -f 1)
    org_guid=$(echo $org | cut -d ":" -f 2)
    if [[ $org_name == "system" ]] || [[ $org_name == "credhub-service-broker-org" ]] || [[ $org_name == "p-spring-cloud-services" ]]
    then
        continue
    fi
    echo $org_name
    labels=$(cf curl /v3/organizations/$org_guid | jq '.metadata.labels' | jq -r 'to_entries[] | (.key) + ": " + (.value)')
    annotations=$(cf curl /v3/organizations/$org_guid | jq '.metadata.annotations' | jq -r 'to_entries[] | (.key) + ": " + (.value)')
    sed -i '' '/metadata/d' ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    sed -i '' '/^$/d' ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    echo "metadata:" >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    echo "  labels:" >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    for label in $labels
    do
        echo "    $label"  >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    done

    echo "  annotations:" >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    for annotation in $annotations
    do
        echo "    $annotation"  >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/orgConfig.yml
    done

    #update all spaces metadata
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
        echo "Space: " $space_name
        labels=$(cf curl /v3/spaces/$space_guid | jq '.metadata.labels' | jq -r 'to_entries[] | (.key) + ": " + (.value)')
        annotations=$(cf curl /v3/spaces/$space_guid | jq '.metadata.annotations' | jq -r 'to_entries[] | (.key) + ": " + (.value)')
        sed -i '' '/metadata/d' ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        sed -i '' '/^$/d' ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        echo "metadata:" >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        echo "  labels:" >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        for label in $labels
        do
            echo "    $label"  >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        done

        echo "  annotations:" >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        for annotation in $annotations
        do
            echo "    $annotation"  >> ~/workspace/TAS/tas-cf-mgmt/config/$org_name/$space_name/spaceConfig.yml
        done


    done


done
