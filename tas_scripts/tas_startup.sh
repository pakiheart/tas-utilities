#!/bin/bash

start_time=$(date)
source ~/bosh_login.sh

IFS=$'\n'
deployments=$(bosh deps --json | jq -r .Tables[].Rows[].name)
echo -e "My Deployments: \n" $deployments

for deployment in $deployments; do
	if [[ "${deployment}" =~ "cf-" ]]; then
		echo "****************** First Starting TAS: " $deployment " ******************"
		bosh -n -d ${deployment} start 
		echo "****************** deployment startup completed ******************"
		break
	fi

done

for deployment in $deployments; do
        if [[ "${deployment}" =~ "cf-" ]]; then
                echo "****************** TAS Already started ******************"
		continue
        fi

	echo "****************** Starting up deployment: " $deployment " ******************"
 	bosh -n -d ${deployment} start 
  	echo "****************** deployment shutdown completed ******************"
done

bosh update-resurrection on
echo "Start Time: " $start_time
echo "End Time: " `date`
