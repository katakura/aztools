#!/bin/bash
#
# Azure KeyVault Firewall rules export tool
# Created by Y.Katakura
#
# usage: ./keyvault-firewall-rule-export.sh
#
# example:
# $ az login --tenant <your tenant>
# $ az account set --subscription <target subscription>
# $ ./keyvault-firewall-rule-export.sh > all-keyvault-fw.csv

#set -e
#set -x

echo '"resourceGroup","resourceName","ipRules"'

az resource list --query "[?type=='Microsoft.KeyVault/vaults'].id" -o tsv |
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

        rules=$(az keyvault network-rule list -g ${resource_group_name} --name ${resource_name} -o json | jq -r '.ipRules[] |= join(",")|.ipRules|@csv')
        echo "\"${resource_group_name}\",\"${resource_name}\",${rules}"
    done

exit 0
