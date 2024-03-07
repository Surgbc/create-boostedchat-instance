#!/bin/bash

subject=$1
body=$2

echo "Subject: $subject" > email.txt
echo "$body" >> email.txt

sendmail "$INSTANCES_EMAIL" < email.txt

rm email.txt

sendmail  < email.txt