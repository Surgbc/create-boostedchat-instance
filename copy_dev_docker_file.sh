#!/bin/bash

copy_docker_yaml_and_create_function() {
    # Check if docker.yaml file exists
    if [ -f "docker-compose.yaml" ]; then
        # Create a function to save the contents of docker.yaml
        cat <<EOF > save_docker_yaml_function.sh
save_docker_yaml() {
    cat <<DOC_EOF > docker-compose.yaml
$(<docker-compose.yaml)
DOC_EOF
    echo "Docker YAML content saved successfully."
}
EOF

    else
        echo "Error: docker.yaml file not found."
    fi
}

copy_docker_yaml_and_create_function

# add to setupvm.sh
replacement_file="setupvm.sh"
line_marker="## replace with docker function"

# Perform the replacement
sed -i "/$line_marker/{r $replacement_file
        d}" save_docker_yaml_function.sh