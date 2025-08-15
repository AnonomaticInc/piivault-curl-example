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

# export PIIVAULT_HOSTNAME="localhost"
# export PIIVAULT_ACCOUNTID=9a183ae2-a472-eb2b-6103-f3e11adaed61
# export PIIVAULT_APIKEY=UyGr87k2wRFy9vTudhi6IaPa10ZugHut
# ./curl-commands.sh --VERB login
# ./curl-commands.sh --VERB login && time ./curl-commands.sh --VERB GetPolyIdBulk --REQUEST ./request-data/test-profiles-1000.1.json 

HOSTP=${HOSTP:-https}
HOSTNAME=${PASSTHROUGH_HOSTNAME:-$PIIVAULT_HOSTNAME}
ACCOUNTID=${PIIVAULT_ACCOUNTID}
APIKEY=${PIIVAULT_APIKEY}
SUNDERID=${PIIVAULT_SUNDERID}
RESPONSE=${RESPONSE:-./response-data/passthroughapi-response.json}

rm -f "${RESPONSE}"

if [[ $HOSTNAME == "" ]]; then
HOSTNAME=${PIIVAULT_HOSTNAME}
fi

while [ $# -gt 0 ]; do

   if [[ $1 == "--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        echo $1 $2
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

curl -S -s -k \
	-X POST "${HOSTP}://${HOSTNAME}/passthrough/api/auth/login" \
	-H "Content-Type: application/json" \
	-H "Content-Encoding: gzip" \
        --data-binary "@./login.dat.gz" \
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

curl -S -s -k \
	-X POST "${HOSTP}://${HOSTNAME}/passthrough/api/auth/login" \
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

curl -S -s -k \
	-X POST "${HOSTP}://${HOSTNAME}/passthrough/api/auth/login" \
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

API_TOKEN=$(jq -r ".Data.Token" api-token.txt)


# 3. Try out the apis below!
case $VERB in

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
DeleteSchema)  # SCHEMAID

echo
echo "$(date): //${HOSTNAME}/passthrough/api/schema/DeleteSchema/${SCHEMAID}"
echo

time curl -S -s -k \
 -X PUT "${HOSTP}://${HOSTNAME}/passthrough/api/schema/DeleteSchema/${SCHEMAID}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" > ${RESPONSE} 

echo
echo "$(date): DeleteSchema"
echo

;;

GetSchemaById) # SCHEMAID

echo
echo "$(date): //${HOSTNAME}/passthrough/api/schema/GetSchema/${SCHEMAID}"
echo

time curl -S -s -k \
 -X GET "${HOSTP}://${HOSTNAME}/passthrough/api/schema/GetSchema/${SCHEMAID}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" > ${RESPONSE}

echo
echo "$(date): GetSchema"
echo

;;

GetSchemaDictionary)

echo
echo "$(date): //${HOSTNAME}/passthrough/api/GetSchemaDictionary"
echo

time curl -S -s -k \
 -X GET "${HOSTP}://${HOSTNAME}/passthrough/api/schema/GetSchemaDictionary" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" > ${RESPONSE}

echo
echo "$(date): GetSchema"
echo

;;

GetAllSchemas)

echo
echo "$(date): //${HOSTNAME}/passthrough/api/schema/GetAllSchemas"
echo

time curl -S -s -k \
 -X GET "${HOSTP}://${HOSTNAME}/passthrough/api/schema/GetAllSchemas" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" > ${RESPONSE}

echo
echo "$(date): GetAllSchemas"
echo

;;

ListSchemaById) # SCHEMAID

echo
echo "$(date): //${HOSTNAME}/passthrough/api/schema/ListSchema/${SCHEMAID}"
echo

time curl -S -s -k \
 -X GET "${HOSTP}://${HOSTNAME}/passthrough/api/schema/ListSchema/${SCHEMAID}" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" > ${RESPONSE}

echo
echo "$(date): ListSchema"
echo

;;

ListAllSchemas)

echo
echo "$(date): //${HOSTNAME}/passthrough/api/schema/ListAllSchemas"
echo

time curl -S -s -k \
 -X GET "${HOSTP}://${HOSTNAME}/passthrough/api/schema/ListAllSchemas" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" > ${RESPONSE}

echo
echo "$(date): ListAllSchemas"
echo

;;

ValidateSchema)

echo
echo "$(date): //${HOSTNAME}/passthrough/api/schema/ValidateSchema"
echo

time curl -S -s -k \
 -X POST "${HOSTP}://${HOSTNAME}/passthrough/api/schema/ValidateSchema" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} > ${RESPONSE}

echo
echo "$(date): ValidateSchema"
echo

;;

SaveSchema)

echo
echo "$(date): START //${HOSTNAME}/passthrough/api/schema/SaveSchema"
echo

time curl -S -s -k \
 -X POST "${HOSTP}://${HOSTNAME}/passthrough/api/schema/SaveSchema" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} > ${RESPONSE}

echo
echo "$(date): FINIS SaveSchema"
echo

;;

CPassthroughAnonymize)

echo
echo "$(date): START //${HOSTNAME}/passthrough/api/profiles/PassthroughAnonymize"
echo

ls -l ${REQUEST}*
gzip -k "${REQUEST}"
ls -l ${REQUEST}*

time curl -S -s -k \
 -X POST "${HOSTP}://${HOSTNAME}/passthrough/api/profiles/PassthroughAnonymize" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" \
 -H "Content-Encoding: gzip" --data-binary "@${REQUEST}.gz" > ${RESPONSE}

echo
echo "$(date): FINIS PassthroughAnonymize"
echo

;;

PassthroughAnonymize)

echo
echo "$(date): START //${HOSTNAME}/passthrough/api/profiles/PassthroughAnonymize"
echo

time curl -S -s -k \
 -X POST "${HOSTP}://${HOSTNAME}/passthrough/api/profiles/PassthroughAnonymize" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} > ${RESPONSE}

echo
echo "$(date): FINIS PassthroughAnonymize"
echo

;;

PassthroughMask)

echo
echo "$(date): START //${HOSTNAME}/passthrough/api/profiles/PassthroughMask"
echo

time curl -S -s -k \
 -X POST "${HOSTP}://${HOSTNAME}/passthrough/api/profiles/PassthroughMask" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} > ${RESPONSE}

echo
echo "$(date): FINIS PassthroughMask"
echo

;;

PassthroughReIdentify)

echo
echo "$(date): START //${HOSTNAME}/passthrough/api/profiles/PassthroughReIdentify"
echo

time curl -S -s -k \
 -X POST "${HOSTP}://${HOSTNAME}/passthrough/api/profiles/PassthroughReIdentify" \
 -H "Authorization: Bearer ${API_TOKEN}" \
 -H "Content-Type: application/json" -d @${REQUEST} > ${RESPONSE}

echo
echo "$(date): FINIS PassthroughReIdentify"
echo

;;


*)

echo
echo "Unknown command verb; check source"
echo

;;

esac


if [[ $VERBOSE > 0 ]]; then
echo ---- [${RESPONSE}] -- ---- -- ---- -- ---- --
cat ${RESPONSE} | head -c 1024
echo
echo
cat ${RESPONSE} | jq '.' | head -n ${VERBOSE}
echo
echo ---- -- ---- -- ---- -- ---- -- ---- -- ---- --
fi

