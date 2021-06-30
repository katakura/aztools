#!/bin/bash
#
# Azure resource dump tool
# Created by Y.Katakura
#
# usage: ./azure-resource-get.sh <Resource Group Name...>
#
# example:
# $ mkdir 20210630
# $ cd 20210630
# $ ../azure-resource-get.sh $(az group list -o tsv --query '[].name')

for arg in "$@"; do
    echo "#### ${arg} ####"
    TARGET_RG=${arg}

    az resource list -g ${TARGET_RG} --query "[].{Name:name,Type:type,ID:id}" -o tsv | sed 's/\t/,/g' | while read line; do
        IFS=','
        set -- $line
        echo $1" ("$2")"
        OUTFILE="${TARGET_RG}/$2/$1.json"
        mkdir -p $(dirname ${OUTFILE})

        az resource show -g ${TARGET_RG} --ids "$3" -o json >${OUTFILE}
    done
done
