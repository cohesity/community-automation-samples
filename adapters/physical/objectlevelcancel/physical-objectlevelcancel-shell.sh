#!/bin/sh
while getopts ":G:O:" opt
do
[ ${OPTARG} = -* ] && { echo "Missing argument for -${opt}" ; exit 1 ; }
    case "${opt}" in
        G) GROUPNAME=${OPTARG};;
	O) OBJECTNAME=${OPTARG};;
      \? ) echo "Usage: cmd [-G][-O]"; exit 1;;
       : ) echo "missing argument for -${OPTARG}"; exit 1;;
    esac
done

echo $GROUPNAME
echo $OBJECTNAME

#Update the variable below
cohesityhost=<cohesity-ip-vip-or-fqdn>

#Get token from cluster and store it in a variable
TOKEN=`curl -k -X POST --url 'https://$cohesityhost/irisservices/api/v1/public/accessTokens' -H 'Accept: application/json' -H 'Content-type: application/json' --data '{"password": "xxxxxxxxxx","username": "xxxxxxx"}' | jq .accessToken`

echo $TOKEN

#Get group id of the feeded group name
GROUPID=`curl -k -X GET "https://$cohesityhost/v2/data-protect/protection-groups" -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -k | jq '.protectionGroups[] | "\(.id) \(.name)"' | tr -d '"' | grep $GROUPNAME | awk '{print $1}'`

echo $GROUPID

#Get object id of the feeded object name that needs to be cancelled
OBJECTID=`curl -k -X GET "https://$cohesityhost/v2/data-protect/protection-groups/$GROUPID" -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -k  | jq . | jq .physicalParams.fileProtectionTypeParams.'objects[] | "\(.id) \(.name)"' | tr -d '"' | grep $OBJECTNAME | awk '{print $1}'`

echo $OBJECTID

#Get last run id
RUNID=`curl -k -X GET "https://$cohesityhost/v2/data-protect/protection-groups/$GROUPID?lastRunAnyStatus=Running&isDeleted=false&includeTenants=true&includeLastRunInfo=true" -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -k  | jq .| jq .lastRun.id | tr -d '"'`

echo $RUNID

#Get last run local task id
LOCALTASKID=`curl -k -X GET "https://$cohesityhost/v2/data-protect/protection-groups/$GROUPID?lastRunAnyStatus=Running&isDeleted=false&includeTenants=true&includeLastRunInfo=true" -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -k  | jq .| jq .lastRun.localBackupInfo.localTaskId | tr -d '"'`

echo $LOCALTASKID

#Cancel Run
curl -k -X POST "https://$cohesityhost/v2/data-protect/protection-groups/$GROUPID/runs/$RUNID/cancel" -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json' -H 'Content-type: application/json' --data "{\"localTaskId\":\"$LOCALTASKID\",\"objectIds\":[$OBJECTID]}"
