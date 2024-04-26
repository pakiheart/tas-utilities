#!/bin/bash

OPSMAN_HOST=""
INSTANCE_PROFILE_NAME=""

# Apply VM extension
uaac curl -k "https://$OPSMAN_HOST/api/v0/staged/vm_extensions/cloud-controller-iam" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d '{"name": "cloud-controller-iam", "cloud_properties": { "iam_instance_profile": '"$INSTANCE_PROFILE_NAME"' }}'

# GET CF Product name
CF_PRODUCT_NAME=$(uaac curl https://$OPSMAN_HOST/api/v0/staged/products -k -b | jq -r '.[]|select(.installation_name | startswith("cf-"))' | jq -r .installation_name)

# Get Jobs GUID
CF_JOBS_GUID=$(uaac curl https://$OPSMAN_HOST/api/v0/staged/products/$CF_PRODUCT_NAME/jobs -k -b | jq -r '.jobs[]|select(.name | startswith("cloud_controller") or startswith("clock_global"))' | jq -r .guid)
IFS=$'\n'
for cf_job_guid in $CF_JOBS_GUID; do
    body=$(uaac curl https://$OPSMAN_HOST/api/v0/staged/products/$CF_PRODUCT_NAME/jobs/$cf_job_guid/resource_config -k -b | jq '.additional_vm_extensions |= . + ["'$INSTANCE_PROFILE_NAME'"]' | jq . -r)
    uaac curl https://$OPSMAN_HOST/api/v0/staged/products/$CF_PRODUCT_NAME/jobs/$cf_job_guid/resource_config -k \
    -X PUT -d "$body"
done