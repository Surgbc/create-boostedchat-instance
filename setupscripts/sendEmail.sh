#!/bin/bash

subject=$1
body=$2

echo "Subject: $subject"
echo "Body: $body"
echo "Subject: $subject" > email.txt
echo "$body" >> email.txt

echo "sending to $INSTANCES_EMAIL"
sendmail "$INSTANCES_EMAIL" < email.txt

rm email.txt