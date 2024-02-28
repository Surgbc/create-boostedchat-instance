#!/bin/bash

# Read the file contents into an array
pwd
mapfile -t lines < ./heldrepos.md

echo  '{"include": [' > heldRepos.json
# Loop over each line in the array
for line in "${lines[@]}"; do
    # Extract the repository URL
    url=$(echo "$line" | grep -oE 'https?://[^ ]+')

    # If no URL found, continue to the next line
    if [[ -z "$url" ]]; then
        continue
    fi

    # Extract the organization name and repository name
    org_repo=$(echo "$url" | sed -E 's|.*/([^/]+)/([^/]+)/?$|\1/\2|')

    # Remove trailing parentheses from the repository name
    org_repo=$(echo "$org_repo" | sed 's/)$//')

    # Split the organization name and repository name
    IFS='/' read -r org repo <<< "$org_repo"

    # Print the organization name and repository name
    echo "Organization: $org, Repository: $repo"
    echo "{\"org\":\"$org\",\"repo\",\"$repo\"}"
    echo "," >> heldRepos.json
done

awk 'NR>1 {print prev} {prev=$0} END {print "]}" }' heldRepos.json > temp && mv temp heldRepos.json # replace last ,
