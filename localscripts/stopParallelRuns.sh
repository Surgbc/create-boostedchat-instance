#!/bin/bash

fullRepo=$1
# workflowName=$workflowName
echo $workflowName
echo $fullRepo

echo "curl -s -H \"Accept: application/vnd.github.v3+json\" -H \"Authorization: Bearer $GH_PAT\"  \"https://api.github.com/repos/$fullRepo/actions/workflows\""

curl -s -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $GH_PAT" \
  "https://api.github.com/repos/$fullRepo/actions/workflows"

response=$(curl -s -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $GH_PAT" \
  "https://api.github.com/repos/$fullRepo/actions/workflows")

WORKFLOW_ID=$(echo "$response" | jq -r '.workflows[] | select(.name == "$workflowName") | .id')

echo $WORKFLOW_ID

curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$fullRepo/actions/workflows/$WORKFLOW_ID/runs"


response=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$fullRepo/actions/workflows/$WORKFLOW_ID/runs")




# Parse the response and extract the IDs of running workflow runs
# Exclude the first running run ID
run_ids=$(echo "$response" | jq -r '.workflow_runs[] | select(.status == "in_progress") | .id')
first_run_id=$(echo "$response" | jq -r '.workflow_runs[] | select(.status == "in_progress") | .id' | head -n 1)
filtered_run_ids=$(echo "$run_ids" | grep -v "$first_run_id")

# Stop each running workflow run (excluding the first one)
for run_id in $filtered_run_ids; do
    echo "Stopping workflow run with ID: $run_id"
    curl -X POST -s -L \
      -H "Authorization: Bearer $GH_PAT" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$fullRepo/actions/runs/$run_id/cancel"
done