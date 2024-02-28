#!/bin/bash


PR_TITLE="Merge dev into main"
PR_BODY="This is an automated pull request created by GitHub Actions"
# PAT="${{ secrets.PAT }}"
PAT=""
REPO_OWNER="LUNYAMWIDEVS"
REPO_NAME="boostedchat-mqtt"
BRANCH_BASE="main"
BRANCH_HEAD="dev"

response=$(curl -X POST \
-H "Authorization: token $PAT" \
-H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls \
-d "{\"title\":\"$PR_TITLE\",\"body\":\"$PR_BODY\",\"head\":\"$BRANCH_HEAD\",\"base\":\"$BRANCH_BASE\"}")

echo $response
PR_URL=$(echo $response | jq -r '.html_url')
echo "Pull request created: $PR_URL"