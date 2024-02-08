#!/bin/bash

PROJECT_ID=$1
WORKLOAD_IDENTITY_POOL=$2
PROVIDER=$3
EMAIL=$4 # length btn 6 and 30
REPO=$5

gcloud iam workload-identity-pools create $WORKLOAD_IDENTITY_POOL --location="global" --project $PROJECT_ID

gcloud iam workload-identity-pools providers create-oidc $PROVIDER \
--location="global" --workload-identity-pool="$WORKLOAD_IDENTITY_POOL"  \
--issuer-uri="https://token.actions.githubusercontent.com" \
--attribute-mapping="attribute.actor=assertion.actor,google.subject=assertion.sub,attribute.repository=assertion.repository" \
--project $PROJECT_ID


gcloud iam service-accounts create $EMAIL \
--display-name="Service account used by WIF POC" \
--project $PROJECT_ID

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$EMAIL@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/compute.viewer"

PROJECT_NUMBER=$(gcloud projects list |grep "^$PROJECT_ID " | awk '{print $NF}' | tr -d '\n')

gcloud iam service-accounts add-iam-policy-binding $EMAIL@$PROJECT_ID.iam.gserviceaccount.com \
--project="$PROJECT_ID" \
--role="roles/iam.workloadIdentityUser" \
--member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WORKLOAD_IDENTITY_POOL/attribute.repository/$REPO"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$EMAIL@$PROJECT_ID.iam.gserviceaccount.com" \
--role=roles/compute.instanceAdmin

echo "$PROJECT_NUMBER"

gcloud iam service-accounts add-iam-policy-binding $EMAIL@$PROJECT_ID.iam.gserviceaccount.com \
--role=roles/iam.serviceAccountUser \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

echo "$PROJECT_NUMBER"
gcloud iam service-accounts add-iam-policy-binding $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
--role=roles/iam.serviceAccountUser \
--member=serviceAccount:$EMAIL@$PROJECT_ID.iam.gserviceaccount.com


echo "service_account: $EMAIL@$PROJECT_ID.iam.gserviceaccount.com"
echo "workload_identity_provider: projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WORKLOAD_IDENTITY_POOL/providers/$PROVIDER"