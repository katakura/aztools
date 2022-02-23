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

get_rest() {
    # az rest -u "https://management.azure.com${1}/${2}?api-version=${3}" |jq '.value[]'
    az rest -u "https://management.azure.com${1}/${2}?api-version=${3}" --exit-status >>$TMPFILE
    if [ $? == "0" ]; then
        echo "," >>$TMPFILE
    fi

}

get_rest_multi() {
    # az rest -u "https://management.azure.com${1}/${2}?api-version=${3}" | jq --exit-status >>$TMPFILE
    az rest -u "https://management.azure.com${1}/${2}?api-version=${3}" | jq '.value[]' --exit-status >>$TMPFILE
    # az rest -u "https://management.azure.com${1}/${2}?api-version=${3}"
    if [ $? == "0" ]; then
        echo "," >>$TMPFILE
    fi

}

get_rest_mysql_config() {
    az rest -u "https://management.azure.com${1}/${2}?api-version=${3}" | jq '.value[]|select (.properties.source != "system-default")' --exit-status >>$TMPFILE
    # az rest -u "https://management.azure.com${1}/${2}?api-version=${3}" | jq '.value[]|select (.properties.source != "system-default")' --exit-status >>$TMPFILE
    if [ $? == "0" ]; then
        echo "," >>$TMPFILE
    fi

}

for arg in "$@"; do
    echo "#### ${arg} ####"
    TARGET_RG=${arg}
    OUTFILE="${TARGET_RG}.json"
    TMPFILE=$(mktemp)
    TMPFILE=tmp.json
    cat <<EOF >$TMPFILE
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
EOF

    az resource list -g ${TARGET_RG} --query '[].id' -o tsv | while read line; do

        if [[ ${line} =~ ^/subscriptions/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/resource[gG]roups/([a-zA-Z0-9_\-].{1,90})/providers/([a-zA-Z\.\d]+/[a-zA-Z]+)/(.+) ]]; then
            subscription_id=${BASH_REMATCH[1]}
            resource_group_name=${BASH_REMATCH[2]}
            resource_type=${BASH_REMATCH[3]}
            resource_name=${BASH_REMATCH[4]}
            # echo "##### $resource_name / $resource_type"
            # echo ${line}
            az resource show -g ${TARGET_RG} --ids "$line" -o json >>$TMPFILE
            echo "," >>$TMPFILE

            if [[ $resource_name =~ / ]]; then
                # echo "### nested resource type is not supported"
                # exit 1
                sleep 0
            else
                case "${resource_type}" in
                "Microsoft.DBforMySQL/servers")
                    get_rest_mysql_config $line configurations 2017-12-01
                    get_rest_multi $line databases 2017-12-01
                    get_rest_multi $line firewallRules 2017-12-01
                    get_rest_multi $line privateEndpointConnections 2018-06-01
                    get_rest_multi $line privateLinkResources 2018-06-01
                    get_rest_multi $line replicas 2017-12-01
                    get_rest_multi $line administrators 2017-12-01
                    get_rest_multi $line virtualNetworkRules 2017-12-01
                    # get_rest_multi $line logFiles 2017-12-01
                    get_rest_multi $line keys 2020-01-01
                    # get_rest $line performanceTiers 2017-12-01
                    ;;
                "Microsoft.Cache/Redis")
                    get_rest_multi $line firewallRules 2021-06-01
                    get_rest_multi $line linkedServers 2021-06-01
                    get_rest_multi $line privateEndpointConnections 2021-06-01
                    get_rest_multi $line privateLinkResources 2021-06-01
                    ;;
                "Microsoft.RecoveryServices/vaults")
                    get_rest_multi $line replicationAlertSettings 2016-08-10
                    get_rest_multi $line backupPolicies 2016-08-10
                    get_rest_multi $line backupProtectedItems 2016-08-10
                    ;;
                esac

            fi
        else
            echo "unknown resource id format"
            exit 1
        fi

        # az rest -u "https://management.azure.com${line}?api-version=2021-12-01"

        # az resource show -g ${TARGET_RG} --ids "$3" -o json >${OUTFILE}
    done
    cat <<EOF >>$TMPFILE
]}
EOF
    sed -i -z -e 's/,\n]}/]}/' $TMPFILE
    sed -i -z -e 's/}\n{/},{/g' $TMPFILE
    cat $TMPFILE | jq >$OUTFILE
    # rm $TMPFILE

done
