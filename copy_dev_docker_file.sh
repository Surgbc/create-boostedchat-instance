#!/bin/bash

copy_docker_yaml_and_create_function() {
    # Check if docker.yaml file exists
    if [ -f "docker-compose.yaml" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > save_docker_yaml_function.sh
save_docker_yaml() {
    cat <<'DOC_EOF' > docker-compose.yaml
$(<docker-compose.yaml)
DOC_EOF
    echo "Docker YAML content saved successfully."
}
EOF

    else
        echo "Error: docker.yaml file not found."
    fi

    if [ -f "pullUpdatedImages.sh" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > savepullUpdatedImages.sh
savePullUpdatedImages() {
    cat <<'DOC_EOF' > /root/pullUpdatedImages.sh
$(<pullUpdatedImages.sh)
DOC_EOF
    chmod +x /root/pullUpdatedImages.sh
    echo "pullUpdatedImages.sh content saved successfully."
}
EOF

    else
        echo "Error: pullUpdatedImages.sh file not found."
    fi
    
    if [ -f "watch.sh" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > saveWatch.sh
saveWatch() {
    cat <<'DOC_EOF' > /root/watch.sh
$(<watch.sh)
DOC_EOF
    chmod +x /root/watch.sh
    echo "watch.sh content saved successfully."
}
EOF

    else
        echo "Error: watch.sh file not found."
    fi
}

copy_docker_yaml_and_create_function

# add to setupvm.sh
replacement_file="save_docker_yaml_function.sh"
line_marker="## replace with docker function"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file


# add to setupvm.sh
replacement_file="savepullUpdatedImages.sh"
line_marker="## replace with savepullUpdatedImages"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file


# add to setupvm.sh
replacement_file="saveWatch.sh"
line_marker="## replace with saveWatch"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" setupvm.sh
rm $replacement_file