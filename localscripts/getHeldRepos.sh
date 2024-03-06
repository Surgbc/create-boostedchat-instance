#!/bin/bash

yaml_file="configs/images.yaml"
owner=$1

get_service_name() {
    local repo_url="$1.git"
    
    # Ensure the YAML file exists
    if [ ! -f "$yaml_file" ]; then
        echo "Error: YAML file '$yaml_file' not found."
        return 1
    fi
    sed -i 's/#.*//g' "$yaml_file" # remove comments
    sed -i 's/^[[:blank:]]*//' "$yaml_file"
    sed -i 's/[[:blank:]]*$//' "$yaml_file"
    # Delete all blank lines
    sed -i '/^[[:space:]]*$/d' "$yaml_file"

    # Put each service section in its own line
    # Replace all newlines that occur after : and any number of trailing whitespaces
    sed -i ':a; $!N; /^\s*[^:]*: *$/{N;ba}; s/\(:\)\s*\n/\1/g' "$yaml_file"

    # Get the service name
    # local service_name=$(grep "$repo_url" "$yaml_file" | sed -E 's/^[[:blank:]]*([^:]+):.*$/\1/')
    # local service_name=$(grep "$repo_url" "$yaml_file" | awk -F: '{print $(NF-3)}')
    devLineNumber=$( sed -e 's/".*//' "$yaml_file" | grep -nE -m 1 'dev:' "$yaml_file" | sed 's/:.*//')
    # devLineNumber=$( sed -e 's/".*//' "$yaml_file" | grep -nE  'dev:' "$yaml_file" | sed 's/:.*//')
#    sed -e 's/".*//' "./configs/images.yaml"  | grep -nE  'dev:' | sed 's/:.*//'
    devLineNumber=$(grep -n -m 1 "$(echo "$(sed -e 's/".*//' "./configs/images.yaml" | grep 'dev:' | grep -vE -m1 -- '-dev:')")" "./configs/images.yaml" | sed 's/:.*//')
    mainLineNumber=$(grep -n -m 1 "$(echo "$(sed -e 's/".*//' "./configs/images.yaml" | grep 'main:' | grep -vE -m1 -- '-main:')")" "./configs/images.yaml" | sed 's/:.*//')
    airflowDevLineNumber=$(grep -n -m 1 "$(echo "$(sed -e 's/".*//' "./configs/images.yaml" | grep 'airflow-dev:' | grep -vE -m1 -- '-airflow-dev:')")" "./configs/images.yaml" | sed 's/:.*//')
    airflowMainLineNumber=$(grep -n -m 1 "$(echo "$(sed -e 's/".*//' "./configs/images.yaml" | grep 'airflow-main:' | grep -vE -m1 -- '-airflow-main:')")" "./configs/images.yaml" | sed 's/:.*//')
    serviceLineNumber=$(grep -n -m 1 "$repo_url" "./configs/images.yaml" | sed 's/:.*//')

    line_numbers=("$devLineNumber" "$mainLineNumber" "$airflowDevLineNumber" "$airflowMainLineNumber")

    while true; do
        found=false
        for num in "${line_numbers[@]}"; do
            if [ "$num" -eq "$serviceLineNumber" ]; then
                case $num in
                    "$devLineNumber") variable="devLineNumber";;
                    "$mainLineNumber") variable="mainLineNumber";;
                    "$airflowDevLineNumber") variable="airflowDevLineNumber";;
                    "$airflowMainLineNumber") variable="airflowMainLineNumber";;
                esac
                # echo "Match found! Variable: ${variable}"
                found=true
                break
            fi
        done

        if [ "$found" = true ]; then
            break
        fi

        ((serviceLineNumber--))
    done
    # echo "==>$variable"

    if [[ $variable == airflow* ]]; then
        airflowService="airflow-"
    else
        airflowService=""
    fi

    # echo "airflowService: $airflowService"

    local service_name=$(grep -m 1 "$repo_url" "$yaml_file" | awk -F: '{print $(NF-3)}')
    # Check if service name is empty
    if [ -z "$service_name" ]; then
        echo "Error: Failed to retrieve service name for repository URL '$repo_url'."
        return 1
    fi

    service_name="$airflowService$service_name"
    # Print the service name
    echo "$service_name"
    return 0
}

# Read the file contents into an array
pwd
# remove organization from urls
# sed -i 's/\[[^\/]*/[ORG/' heldrepos.md 
sort -u heldrepos.md > /tmp/heldrepos.md
mv /tmp/heldrepos.md heldrepos.md
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
    serviceName=$(get_service_name  "$org/$repo")
    echo "Organization: $org, Repository: $repo,\"service\":\"$serviceName\""
    echo "{\"org\":\"$owner\",\"repo\":\"$repo\",\"service\":\"$serviceName\"}" >> heldRepos.json
    echo "," >> heldRepos.json
done

awk 'NR>1 {print prev} {prev=$0} END {print "]}" }' heldRepos.json > temp && mv temp heldRepos.json # replace last ,
