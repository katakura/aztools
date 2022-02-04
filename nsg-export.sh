#!/bin/bash
#
# Azure Network Security Group export tool
# Created by Y.Katakura
#
# usage: ./nsg-export.sh
#
# example:
# $ az login --tenant <your tenant>
# $ az account set --subscription <target subscription>
# $ ./nsg-export.sh > all-nsg.csv

#set -e
#set -x

echo '"resourceGroup","resourceName","direction","priority","name","protocol","sourceAddressPrefix","sourcePortRangs","destinationAddressPrefixes","destinationPortRanges","access","description"'

az resource list --query "[?type=='Microsoft.Network/networkSecurityGroups'].id" -o tsv |
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

        az network nsg rule list -g ${resource_group_name} --nsg-name ${resource_name} -o json |
            jq ".[] |= .+ {\"resourceName\": \"${resource_name}\"}" |
            jq -r '.[] |
                .sourcePortRanges |= join(",") |
                .destinationPortRanges |= join(",") |
                .sourceAddressPrefixes |= join(",") |
                .destinationAddressPrefixes |= join(",") |
                .protocolup = .protocol |
                .protocoldown = .protocol |
                .protocolup |= ascii_upcase |
                .protocoldown |= ascii_downcase |
                .protocol = .protocolup[0:1]+.protocoldown[1:] |
                [
                    .resourceGroup,
                    .resourceName,
                    .direction,
                    .priority,
                    .name,
                    .protocol,
                    if .sourceAddressPrefixes == "" then .sourceAddressPrefix else .sourceAddressPrefixes end,
                    if .sourcePortRanges == "" then .sourcePortRange else .sourcePortRanges end,
                    if .destinationAddressPrefixes == "" then .destinationAddressPrefix else .destinationAddressPrefixes end,
                    if .destinationPortRanges == "" then .destinationPortRange else .destinationPortRanges end,
                    .access,
                    .description
                ]
                | @csv'
    done
exit 0
