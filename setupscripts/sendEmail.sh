#!/bin/bash

subject=$1
body=$2

echo "Subject: $subject"
echo "Body: $body"
echo "Subject: $subject" > email.txt
echo "" >> email.txt
echo "$body"| sed 's/\\n/\n/' >> email.txt
sed -i 's/^[[:space:]]*//' email.txt

echo "cating email"
cat email.txt

echo "sending to $INSTANCES_EMAIL"
sendmail "$INSTANCES_EMAIL" < email.txt

rm email.txt