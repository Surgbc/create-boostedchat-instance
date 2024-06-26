#!/bin/bash

subdomain=$SUBDOMAIN

subdomains=(
    "${subdomain}"
    "airflow.${subdomain}"
    "api.${subdomain}"
    "promptemplate.${subdomain}"
    "scrapper.${subdomain}"
    "mqtt.${subdomain}"
)

# Cloudflare API endpoint URL
URL="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records"

# Cloudflare API Token
TOKEN="Bearer ${CLOUDFLARE_API_TOKEN}"

# Iterate over each subdomain and create DNS records
for sub in "${subdomains[@]}"; do
    # DNS record details
    DNS_RECORD_DATA='{
        "type": "A",
        "name": "'"${sub}"'",
        "content": "'"${IP}"'",
        "ttl": 120,
        "proxied": false
    }'

    # delete before creating new
    DNS_RECORDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?type=A&name=${sub}.boostedchat.com" \
    -H "Authorization: $TOKEN" \
    -H "Content-Type: application/json")

    RECORD_IDS=$(echo "$DNS_RECORDS" | jq -r '.result[].id')

    # Loop through record IDs and delete each record
    for record_id in $RECORD_IDS; do
        echo "Deleting DNS record with ID: $record_id"
        curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_id" \
            -H "Authorization: $TOKEN" \
            -H "Content-Type: application/json"
    done

    # Make the POST request to create the DNS record
    RESPONSE=$(curl -X POST -s -H "Authorization: ${TOKEN}" -H "Content-Type: application/json" -d "${DNS_RECORD_DATA}" "${URL}")

    # Check the response status
    if [ "$(echo "${RESPONSE}" | jq -r '.success')" == "true" ]; then
        CREATED_RECORD_ID=$(echo "${RESPONSE}" | jq -r '.result.id')
        echo "DNS record created successfully for ${sub}: ID ${CREATED_RECORD_ID}"
    else
        echo "Failed to create DNS record for ${sub}."
        echo "${RESPONSE}"
    fi
done