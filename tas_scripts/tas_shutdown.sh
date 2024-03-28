#!/bin/bash

start_time=$(date)
source ~/bosh_login.sh
bosh update-resurrection off

IFS=$'\n'
deployments=$(bosh deps --json | jq -r .Tables[].Rows[].name)
echo "My Deployments: \n" $deployments
tas_deployment=""
for deployment in $deployments; do
  if [[ "${deployment}" =~ "cf-" ]]; then
	  tas_deployment=$deployment
	  echo "****************** Skipping TAS, will shutdown at the end ******************"
	  continue
  fi
  echo "****************** Shutting down deployment: " $deployment " ******************"
  bosh -n -d ${deployment} stop  --hard --skip-drain --max-in-flight=3
  echo "****************** deployment shutdown completed ******************"
done

echo "****************** Shutting down deployment: " $tas_deployment " ******************"
bosh -n -d ${tas_deployment} stop  --hard --skip-drain --max-in-flight=3
echo "****************** deployment shutdown completed ******************"

echo "Start Time: " $start_time
echo "End Time: " `date`
