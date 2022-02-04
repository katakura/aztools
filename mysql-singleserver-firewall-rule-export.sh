#!/bin/bash
#
# Azure database for MySQL (single server) Firewall rules export tool
# Created by Y.Katakura
#
# usage: ./mysql-singleserver-firewall-rule-export.sh
#
# example:
# $ az login --tenant <your tenant>
# $ az account set --subscription <target subscription>
# $ ./mysql-singleserver-firewall-rule-export.sh > all-mysql-fw.csv

#set -e
#set -x

echo '"resourceGroup","resourceName","name","startIpAddress","endIpAddress"'

az resource list --query "[?type=='Microsoft.DBforMySQL/servers'].id" -o tsv |
    while read nsgs; do
        if [[ ${nsgs} =~ ^/subscriptions/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/resource[gG]roups/([a-zA-Z0-9_\-].{1,90})/providers/([a-zA-Z\.\d]+/[a-zA-Z]+)/(.+) ]]; then
            subscription_id=${BASH_REMATCH[1]}
            resource_group_name=${BASH_REMATCH[2]}
            resource_provider=${BASH_REMATCH[3]}
            resource_name=${BASH_REMATCH[4]}
            if [[ $resource_name =~ / ]]; then
                echo "nested resource type is not supported"
                exit 1
            fi
        else
            echo "unknown resource id format"
            exit 1
        fi

        az mysql server firewall-rule list -g ${resource_group_name} --server-name ${resource_name} -o json |
            jq ".[] |= .+ {\"resourceName\": \"${resource_name}\"}" |
            jq -r '.[] |
                [
                    .resourceGroup,
                    .resourceName,
                    .name,
                    .startIpAddress,
                    .endIpAddress
                ]
                | @csv'
    done
exit 0
