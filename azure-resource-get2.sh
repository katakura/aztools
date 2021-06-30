#!/bin/bash
#
# Azure resource dump tool 2
# Created by Y.Katakura
#
# usage: ./azure-resource-get2.sh <Resource Group Name...>
#
# example:
# $ mkdir 20210630
# $ cd 20210630
# $ ../azure-resource-get2.sh $(az group list -o tsv --query '[].name')

for arg in "$@"; do
    echo "#### ${arg} ####"
    TARGET_RG=${arg}
    OUTFILE="${TARGET_RG}.json"
    TMPFILE=$(mktemp)
cat <<EOF > $TMPFILE
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
EOF
    az resource list -g ${TARGET_RG} --query "[].{Name:name,Type:type,ID:id}" -o tsv | sed 's/\t/,/g' | while read line; do
        IFS=','
        set -- $line
        echo $1" ("$2")"

        az resource show -g ${TARGET_RG} --ids "$3" -o json >> $TMPFILE
        echo "," >> $TMPFILE
    done
cat <<EOF >> $TMPFILE
]}
EOF
    sed -i -z -e 's/,\n]}/]}/' $TMPFILE
    cat $TMPFILE | jq > $OUTFILE
    rm $TMPFILE
done
