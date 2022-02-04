# README

## nsg-export.sh

This program will scan all the NSGs in the specified Azure subscription and output them in csv format.

usage:

```bash
$ ./nsg-export.sh
```

example:

```bash
$ az login --tenant <your tenant>
$ az account set --subscription <target subscription>
$ ./nsg-export.sh > all-nsg.csv
```

## mysql-singleserver-firewall-rule-export.sh

This program will scan all the MySQL ACLs in the specified Azure subscription and output them in csv format.

usage:

```bash
$ ./mysql-singleserver-firewall-rule-export.sh
```

example:

```bash
$ az login --tenant <your tenant>
$ az account set --subscription <target subscription>
$ ./mysql-singleserver-firewall-rule-export.sh > all-mysql-fw.csv
```

## azure-resource-get.sh

This program will run the Azure CLI "az resource show" command for all resources in the specified resource group.

The output json file will be created and saved in a directory for each resource provider under the current directory.

The version of Azure CLI is confirmed to be 2.25.0, but even if it is a little older, it will not be a problem.

usage:

```bash
$ ./azure-resource-get.sh <Resource Group Name...>
```

example(Targeting all resource groups):

```bash
$ mkdir 20210630
$ cd 20210640
$ ../azure-resource-get.sh $(az group list -o tsv --query '[].name')
```
