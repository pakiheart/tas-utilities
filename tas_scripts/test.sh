#!/bin/bash

Domain_Name="rehan.com"
routes=$(cf curl /v3/apps/b99cf015-7c66-4708-8144-b8ac8b15444b/routes | jq -r '.resources[] | .host + ":" + .path + ":" + .url')
for route in $routes; do
    echo $route
        host=$(echo $route | cut -d ":" -f 1)
        path=$(echo $route | cut -d ":" -f 2)
        url=$(echo $route | cut -d ":" -f 3)
        echo $host
        echo $path
        echo $url
        if [[ $url == *.$Domain_Name ]]; then
            echo "It Exists"
        else
            echo "Does not Exists"
        fi

done