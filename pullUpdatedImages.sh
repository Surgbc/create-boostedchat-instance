#!/bin/bash

cd /root/boosted-chat
# Find the docker-compose file
compose_file=$(find . -type f \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \))

if [ -z "$compose_file" ]; then
    echo "No docker-compose.yml or docker-compose.yaml found."
    exit 1
fi

# Function to check if image needs update
needs_update() {
    local image="$1"
    local status=$(docker pull "$image" | grep -o "Status: Image is up to date")
    echo "$image: $status"
    if [ -z "$status" ]; then
        return 0
    else
        return 1
    fi
}

# Restart services if needed
services_to_restart=()
images=$(grep -E '^\s+image:' "$compose_file" | awk '{print $2}')
for image in $images; do
    if needs_update "$image"; then
        services_to_restart+=($(grep -E '^\s+image:' "$compose_file" | grep -B1 "$image" | grep -o '^\s\+\S\+:' | sed 's/://'))
    fi
done

if [ ${#services_to_restart[@]} -eq 0 ]; then
    echo "No services need to be restarted."
else
    echo "Restarting services:"
    for service in "${services_to_restart[@]}"; do
        docker compose -f "$compose_file" restart "$service"
    done
fi
