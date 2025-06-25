#!/bin/bash

# List of images and their versions
IMAGES=(
  "ghcr.io/projects-in3-uds/notification:1.0.1"
  "ghcr.io/projects-in3-uds/invitation:1.0.1"
  "ghcr.io/projects-in3-uds/billing:1.0.1"
  "ghcr.io/projects-in3-uds/reservation:1.0.1"
  "ghcr.io/projects-in3-uds/iam:1.0.1"
  "ghcr.io/projects-in3-uds/gateway:1.0.1"
  "ghcr.io/projects-in3-uds/configserver:1.0.1"
  "ghcr.io/projects-in3-uds/postgres:16"
)

# Authenticate with GHCR
echo "Authenticating with GHCR..."
# Replace <USERNAME> and <PERSONAL_ACCESS_TOKEN> with your credentials
# docker login ghcr.io -u <USERNAME> -p <PERSONAL_ACCESS_TOKEN>

# Push each image
for IMAGE in "${IMAGES[@]}"; do
  echo "Pushing $IMAGE..."
  docker push "$IMAGE"
done

echo "All images have been pushed to GHCR."
