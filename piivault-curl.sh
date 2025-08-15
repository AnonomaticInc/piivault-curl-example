#!/usr/bin/env bash
# https://kvz.io/bash-best-practices.html
# Bash3 Boilerplate. Copyright (c) 2014, kvz.io

set -o errexit
set -o pipefail
#set -o nounset
#set -o xtrace  # echo each line executed

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

#arg1="${1:-}"

# ./curl-commands.sh --HOSTNAME "localhost:53043" --VERB PurgeAccountProfile --ACCOUNTID 88fb13a4-b14d-b1fb-cac5-9da45ad29a51 --APIKEY 3a98wl4UBxWpDTbDPF8DCLkaKe6Vfosb
# ./curl-commands.sh --HOSTNAME "localhost:53043" --VERB GetPolyIdBulk --ACCOUNTID 88fb13a4-b14d-b1fb-cac5-9da45ad29a51 --APIKEY 3a98wl4UBxWpDTbDPF8DCLkaKe6Vfosb --REQUEST sunder-test-10k.json
# ./curl-commands.sh --HOSTNAME "localhost:53043" --VERB Match --ACCOUNTID 88fb13a4-b14d-b1fb-cac5-9da45ad29a51 --APIKEY 3a98wl4UBxWpDTbDPF8DCLkaKe6Vfosb --REQUEST match-request.json
# ./curl-commands.sh --HOSTNAME "localhost:53043" --VERB GetProfilePseudonym --ACCOUNTID 88fb13a4-b14d-b1fb-cac5-9da45ad29a51 --APIKEY 3a98wl4UBxWpDTbDPF8DCLkaKe6Vfosb --REQUEST getprofilepseudonym-request.json

HOSTNAME=${PIIVAULT_HOSTNAME}
ACCOUNTID=${PIIVAULT_ACCOUNTID}
APIKEY=${PIIVAULT_APIKEY}
SUNDERID=${PIIVAULT_SUNDERID}

while [ $# -gt 0 ]; do
#   echo $1
   if [[ $1 == "--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
#        echo $1 $2
   fi

  shift
done

case $VERB in

clogin)
# 1. Use the AccountId, and API Key provided by Anonomatic to get a Bearer Token
# -- POST login --
rm -f api-token.txt

echo "{ \"AccountId\": \"${ACCOUNTID}\", \"ApiKey\": \"${APIKEY}\" }" > login.dat
gzip login.dat

curl -k \
	-X POST "https://${HOSTNAME}/piivault/api/auth/login" \
	-H "Content-Type: application/json" \
	-H "Content-Encoding: gzip" \
	--data-binary "@login.dat.gz" \
> api-token.txt

echo -- -- -- -- API TOKEN -- -- -- --
cat api-token.txt
echo
echo -- -- -- -- API TOKEN -- -- -- --

exit

;;

login)
# 1. Use the AccountId, and API Key provided by Anonomatic to get a Bearer Token
# -- POST login --
rm -f api-token.txt

curl -k \
	-X POST "https://${HOSTNAME}/piivault/api/auth/login" \
	-H "Content-Type: application/json" \
-d "{ \"AccountId\": \"${ACCOUNTID}\", \"ApiKey\": \"${APIKEY}\" }" \
> api-token.txt

echo -- -- -- -- API TOKEN -- -- -- --
cat api-token.txt
echo
echo -- -- -- -- API TOKEN -- -- -- --

exit


;;

loginWithSunder)
# 1. Use the AccountId, and API Key provided by Anonomatic to get a Bearer Token
# -- POST login --
rm -f api-token.txt

curl -k \
	-X POST "https://${HOSTNAME}/piivault/api/auth/login" \
	-H "Content-Type: application/json" \
-d "{ \"AccountId\": \"${ACCOUNTID}\", \"ApiKey\": \"${APIKEY}\", \"SunderId\": \"${SUNDERID}\" }" \
> api-token.txt

echo -- -- -- -- API TOKEN -- -- -- --
cat api-token.txt
echo
echo -- -- -- -- API TOKEN -- -- -- --

exit


;;

esac

# 2. Copy the token from the JSON Payload of the above response to here (or use jq)
# NOTE: This uses https://stedolan.github.io/jq/ to set the API_TOKEN

#echo "##############################"
#cat api-token.txt
#echo "##############################"
API_TOKEN=$(jq -r ".Data.Token" api-token.txt)
#echo "##############################"
#echo $API_TOKEN
#echo "##############################"

# 3. Try out the apis below!
case $VERB in

GetProfileStream)

>&2 echo
>&2 echo "START //${HOSTNAME}/piivault/api/profiles/GetProfileStream: $(date)"
>&2 echo

curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/profiles/GetProfileStream${QUERY}" \
 -H "Authorization: Bearer ${API_TOKEN}"

>&2 echo
>&2 echo "FINIS GetProfileStream: $(date)"
>&2 echo

;;


PutProfileStream)

>&2 echo
>&2 echo "START //${HOSTNAME}/piivault/api/profiles/PutProfileStream: $(date)"
>&2 echo

PUT_FILE_SIZE=`du "$REQUEST" | cut -f1`

cat "${REQUEST}" | curl -v -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/PutProfileStream${QUERY}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/text" --upload-file -

>&2 echo
>&2 echo "FINIS PutProfileStream: $(date)"
>&2 echo

;;

GetKeyTypes)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetKeyTypes: $(date)"
echo

curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/profiles/GetKeyTypes" \
 -H "Authorization: Bearer ${API_TOKEN}"  | jq '.'

echo
echo "FINIS GetKeyTypes: $(date)"
echo

;;

CGetPolyId)
## -- PUT GetPolyId --

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetPolyId: $(date)"
echo
ls -l ${REQUEST}*
gzip -k "${REQUEST}"
ls -l ${REQUEST}*

curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetPolyId" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Encoding: gzip" \
 -H "Content-Type: application/json" --data-binary "@${REQUEST}.gz"  > ./response-data/getpolyid-response.json

echo
echo "FINIS GetPolyId: $(date)"
echo

cat ./response-data/getpolyid-response.json | jq '.' | head -n 25

;;

GetPolyId)
## -- PUT GetPolyId --

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetPolyId: $(date)"
echo

curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetPolyId" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/getpolyid-response.json

echo
echo "FINIS GetPolyId: $(date)"
echo

cat ./response-data/getpolyid-response.json | jq '.' | head -n 25

;;

GetProfileSourceSystemKey)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetProfileIds: $(date)"
echo

curl -s -k --compressed \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfileIds" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d "{ \"Ids\": [{ \"Index\": 1, \"PolyId\": \"${ID}\" }] \"" > ./response-data/getprofileids-response.json

cat ./response-data/getprofileids-response.json | jq '.' | head -n 25

echo
echo "FINIS GetProfileIds: $(date)"
echo

;;

GetProfilePolyId)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetProfileIds: $(date)"
echo

curl -s -k --compressed \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfileIds" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json"  -d "{ \"Ids\": [{ \"Index\": 1, \"SourceSystemKey\": \"${ID}\" }] \"" > ./response-data/getprofileids-response.json

cat ./response-data/getprofileids-response.json | jq '.' | head -n 25

echo
echo "FINIS GetProfileIds: $(date)"
echo

;;

GetProfileIds)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetProfileIds: $(date)"
echo

curl -s -k --compressed \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfileIds" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} > ./response-data/getprofileids-response.json

cat ./response-data/getprofileids-response.json | jq '.' | head -n 25

echo
echo "FINIS GetProfileIds: $(date)"
echo

;;

GetPolyIdWithPseudonym)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetPolyIdWithPseudonym: $(date)"
echo

rm -f ./reponse-data/getpolyid-response.json

curl -s -k --compressed \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetPolyIdWithPseudonym" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} > ./response-data/getpolyid-response.json

cat ./response-data/getpolyid-response.json | jq '.' | head -n 25

echo
echo "FINIS GetPolyIdWithPseudonym: $(date)"
echo

;;

ForgetProfiles)

echo
echo "START ForgetProfile: $(date)"
echo

curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/ForgetProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} > ./response-data/forgetprofile-response.json

cat ./response-data/forgetprofile-reponse.json | jq '.' | head -n 25

echo
echo "FINIS ForgetProfile: $(date)"
echo

;;

ForgetProfileByPolyId)

echo
echo "START ForgetProfile: $(date)"
echo

curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/ForgetProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d "{ \"Ids\": [{ \"Index\": 1, \"PolyId\": \"${ID}\" }] \"" > ./response-data/forgetprofile-response.json

cat ./response-data/forgetprofile-reponse.json | jq '.' | head -n 25

echo
echo "FINIS ForgetProfile: $(date)"
echo

;;

ForgetProfileBySourceSystemKey)

echo
echo "START ForgetProfile: $(date)"
echo

curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/ForgetProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d "{ \"Ids\": [{ \"Index\": 1, \"SourceSystemKey\": \"${ID}\" }] \"" > ./response-data/forgetprofile-response.json


cat ./response-data/forgetprofile-reponse.json | jq '.' | head -n 25

echo
echo "FINIS ForgetProfile: $(date)"
echo

;;

DeleteProfiles)

echo
echo "START DeleteProfile: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/DeleteProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} > ./response-data/deleteprofile-response.json

cat ./response-data/deleteprofile-response.json | jq '.' | head -n 20

echo
echo "END   DeleteProfile: $(date)"
echo

;;

DeleteProfileByPolyId)

echo
echo "START DeleteProfile: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/DeleteProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d "{ \"Ids\": [{ \"Index\": 0, \"PolyId\": \"${ID}\" }]}" > ./response-data/deleteprofile-response.json

cat ./response-data/deleteprofile-response.json | jq '.' | head -n 20

echo
echo "END   DeleteProfile: $(date)"
echo

;;

DeleteProfileBySourceSystemKey)

echo
echo "START DeleteProfile: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/DeleteProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d "{ \"Ids\": [{ \"Index\": 0, \"SourceSystemKey\": \"${ID}\" }]}" > ./response-data/deleteprofile-response.json

cat ./response-data/deleteprofile-response.json | jq '.' | head -n 20

echo
echo "END   DeleteProfile: $(date)"
echo

;;

PurgeAccountProfiles)

echo
echo "START /piivault/api/profiles/PurgeAccountProfiles: $(date)"
echo

curl -k \
-X PUT "https://${HOSTNAME}/piivault/api/profiles/PurgeAccountProfiles" \
-H "Authorization: Bearer ${API_TOKEN}" \
-H "Content-Length: 0"

echo
echo "FINIS PurgeAccountProfiles: $(date)"
echo

;;

CancelMatchTask)

echo
echo "START CancelMatchTask: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/match/CancelMatchTask" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Length: 0" | jq '.' > ./response-data/execute-match.json

echo
echo "END   CancelMatchTask: $(date)"
echo

;;

ExecuteMatch)

echo
echo "START ExecuteMatchTask: $(date)"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/match" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} | jq '.' > ./response-data/execute-match.json

echo
echo "END   ExecuteMatchTask: $(date)"
echo

head -n 25 ./response-data/execute-match.json

;;

TestMatch)

echo
echo "START TestMatchTask: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/match/TestMatchTask" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} | jq '.' > ./response-data/test-match.json

echo
echo "END   TestMatchTask: $(date)"
echo

head -n 25 ./response-data/test-match.json

;;

GetMatchResult)

echo
echo "START GetMatchResult)"
echo

curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/match/GetMatchResult" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  | jq '.' >  ./response-data/match-response.json

echo
echo "END   GetMatchResult: $(date)"
echo

head -n 25 ./response-data/match-response.json

;;

GetMatchTaskStatus)

echo
echo "START GetMatchTaskStatus: $(date)"
echo

curl -k \
 "https://${HOSTNAME}/piivault/api/match/GetMatchTaskStatus" \
 -H "Authorization: Bearer ${API_TOKEN}" # | jq '.' >  ./response-data/match-status-response.json

echo
echo "END   GetMatchTaskStatus: $(date)"
echo

;;

GetSecondaryPolyId)

echo
echo "START GetSecondaryPolyId: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetSecondaryPolyId" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json"  -d @${REQUEST} | jq '.' > ./response-data/getsecondarypolyid-response.json

head -n 25 ./response-data/getsecondarypolyid-response.json

echo
echo "END   GetSecondaryPolyId: $(date)"
echo

;;

GetProfiles)

echo
echo "START GetProfile: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -d @${REQUEST} > ./response-data/getprofile-response.json

cat ./response-data/getprofile-response.json | jq '.' | head -n 20

echo
echo "END   GetProfile: $(date)"
echo

;;

GetProfileBySourceSystemKey)

echo
echo "START GetProfileBySourceSystemKey: $(date)"
echo

curl -s -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -d "{ \"Ids\": [{ \"Index\": 1, \"SourceSystemKey\": \"${ID}\" }] }" > ./response-data/getprofile-response.json

cat ./response-data/getprofile-response.json | jq '.' | head -n 20

echo
echo "END   GetProfileBySourceSystemKey: $(date)"
echo

;;

GetProfileByPolyId)

echo
echo "START GetProfileByPolyId: $(date)"
echo

REQUEST="{\"Ids\":[{\"Index\":1,\"PolyId\":\"${ID}\"}]}"
echo $REQUEST

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfile" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -d "$REQUEST" > ./response-data/getprofile-response.json

cat ./response-data/getprofile-response.json | jq '.' | head -n 20

echo
echo "END   GetProfileByPolyId: $(date)"
echo

;;

GetProfilePseudonym)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetProfilePseudonym: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfilePseudonym" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -d @${REQUEST} > ./response-data/getprofilepseudonym-response.json


cat ./response-data/getprofilepseudonym-response.json | jq '.' | head -n 20

echo
echo "FINIS GetProfilePseudonym: $(date)"
echo

;;

GetProfilePseudonymByPolyId)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetProfilePseudonym: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfilePseudonym" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -d "{ \"Ids\": [ { \"Index\": 1, \"PolyId\": \"${ID}\" }], \"Seed\": ${SEED:-37} }" | jq '.' > ./response-data/getprofilepseudonym-response.json


cat ./response-data/getprofilepseudonym-response.json | jq '.' | head -n 20

echo
echo "FINIS GetProfilePseudonym: $(date)"
echo

;;

GetProfilePseudonymBySourceSystemKey)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/GetProfilePseudonym: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/profiles/GetProfilePseudonym" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -d "{ \"Ids\": [ { \"Index\": 1, \"SourceSystemKey\": \"${ID}\"}], \"Seed\": ${SEED:-37} }" | jq '.' > ./response-data/getprofilepseudonym-response.json


cat ./response-data/getprofilepseudonym-response.json | jq '.' | head -n 20

echo
echo "FINIS GetProfilePseudonym: $(date)"
echo

;;

RedactText)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/RedactText: $(date)"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/RedactText" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} | jq '.' > ./response-data/redact-response.json

echo
echo "FINIS RedactText: $(date)"
echo

cat ./response-data/redact-response.json

;;

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
GetSchemaById)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetSchema/${SCHEMAID}"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetSchema/${SCHEMAID}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getschema-response.json

echo
echo "FINIS GetSchema"
echo

cat ./response-data/getschema-response.json

;;

GetSchemaByName)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetSchema/${SCHEMAGROUP}/${SCHEMASUBGROUP}/${SCHEMANAME}"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetSchema/${SCHEMAGROUP}/${SCHEMASUBGROUP}/${SCHEMANAME}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getschema-response.json

echo
echo "FINIS GetSchema"
echo

cat ./response-data/getschema-response.json

;;

GetSchemaGroups)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetSchemaGroups"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetSchemaGroups" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getschema-response.json

echo
echo "FINIS GetSchemaGroups"
echo

cat ./response-data/getschema-response.json

;;

GetSchemaSubGroups)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetSchemaSubGroups/${SCHEMAGROUP}"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetSchemaSubGroups/${SCHEMAGROUP}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getschema-response.json

echo
echo "FINIS GetSchemaSubGroups"
echo

cat ./response-data/getschema-response.json

;;

GetSchemaGroup)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetSchemaGroup/${SCHEMAGROUP}"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetSchemaGroup/${SCHEMAGROUP}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getschema-response.json

echo
echo "FINIS GetSchemaGroup"
echo

cat ./response-data/getschema-response.json

;;

GetSchemaSubGroup)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetSchemaSubGroup/${SCHEMAGROUP}/${SCHEMASUBGROUP}"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetSchemaSubGroup/${SCHEMAGROUP}/${SCHEMASUBGROUP}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getschema-response.json

echo
echo "FINIS GetSchemaSubGroup"
echo

cat ./response-data/getschema-response.json

;;

GetAllSchema)

echo
echo "START //${HOSTNAME}/piivault/api/schema/GetAllSchema"
echo

time curl -k \
 -X GET "https://${HOSTNAME}/piivault/api/schema/GetAllSchema" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" | jq '.' > ./response-data/getallschema-response.json

echo
echo "FINIS GetAllSchema"
echo

cat ./response-data/getallschema-response.json

;;

AddSchema)

echo
echo "START //${HOSTNAME}/piivault/api/schema/AddSchema"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/schema/AddSchema" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} | jq '.' > ./response-data/addschema-response.json

echo
echo "FINIS AddSchema"
echo

cat ./response-data/addschema-response.json

;;

UpdateSchema)

echo
echo "START //${HOSTNAME}/piivault/api/schema/UpdateSchema"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/schema/UpdateSchema" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} | jq '.' > ./response-data/updateschema-response.json

echo
echo "FINIS UpdateSchema"
echo

cat ./response-data/updateschema-response.json

;;

DeleteSchema)

echo
echo "START //${HOSTNAME}/piivault/api/schema/DeleteSchema/${SCHEMAID}"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/schema/DeleteSchema/${SCHEMAID}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json"  | jq '.' > ./response-data/deleteschema-response.json

echo
echo "FINIS DeleteSchema"
echo

cat ./response-data/deleteschema-response.json

;;

EncryptAES)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/EncryptAES"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/EncryptAES" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/encrypt-aes-response.json

echo
echo "FINIS EncryptAEs"
echo

cat ./response-data/encrypt-aes-response.json | (jq '.' || echo) | head -n 20

;;


DecryptAES)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/DecryptAES"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/DecryptAES" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/decrypt-aes-response.json

echo
echo "FINIS DecryptAEs"
echo

cat ./response-data/decrypt-aes-response.json | (jq '.' || echo) | head -n 20

;;

Decrypt)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/Decrypt"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/Decrypt" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/decrypt-response.json

echo
echo "FINIS Decrypt"
echo

cat ./response-data/decrypt-response.json | jq '.' | head -n 20

;;

PolyAnonymize)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/PolyAnonymize"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/PolyAnonymize" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/polyanonymize-response.json

echo
echo "FINIS PolyAnonymize"
echo

cat ./response-data/polyanonymize-response.json | jq '.' | head -n 20

;;

DePolyAnonymize)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/DePolyAnonymize"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/DePolyAnonymize" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/depolyanonymize-response.json

echo
echo "FINIS DePolyanonymize"
echo

cat ./response-data/depolyanonymize-response.json | jq '.' | head -n 20

;;


Encryptor)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/Encryptor"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/Encryptor" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/encryptor-response.json

echo
echo "FINIS Encryptor"
echo

cat ./response-data/encryptor-response.json | jq '.' | head -n 20

;;

Decryptor)

echo
echo "START //${HOSTNAME}/piivault/api/profiles/Decryptor"
echo

time curl -k \
 -X POST "https://${HOSTNAME}/piivault/api/profiles/Decryptor" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST}  > ./response-data/decryptor-response.json

echo
echo "FINIS Decryptor"
echo

cat ./response-data/decryptor-response.json | jq '.' | head -n 20

;;

SynchronousLookup)

echo
echo "START SynchronousLookup: $(date)"
echo

time curl -k \
 -X PUT "https://${HOSTNAME}/piivault/api/lookup" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Type: application/json" -d @${REQUEST} | jq '.' > ./response-data/synchronous-lookup-response.json

echo
echo "END   SynchronousLookup: $(date)"
echo

head -n 25 ./response-data/synchronous-lookup-response.json

;;


*)

echo
echo "Unknown command verb; check source"
echo


;;

esac

