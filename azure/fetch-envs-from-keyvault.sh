#!/bin/bash

set -e

# Function to install Azure CLI (for Ubuntu/Debian)
install_az_cli() {
  echo "Azure CLI not found. Installing Azure CLI..."
  sudo apt-get update
  sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y
  curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
  AZ_REPO=$(lsb_release -cs)
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list
  sudo apt-get update
  sudo apt-get install azure-cli -y
}

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
  install_az_cli
else
  echo "Azure CLI is already installed."
fi

# Login check (for interactive use; adjust if using managed identity or automation)
if ! az account show &> /dev/null; then
  echo "Please log in to Azure CLI."
  az login
fi

# List your services here
services=("billing" "iam" "invitation" "gateway" "config-server" "reservation" "notification")
vault_name="amcloud"
env_dir="./env"

mkdir -p "$env_dir"

for service in "${services[@]}"; do
  secret_name="env-$service"
  raw_env="$env_dir/.env.$service.raw"
  fixed_env="$env_dir/.env.$service"
  # Fetch secret (may be JSON string with escaped newlines and quotes)
  az keyvault secret show --name "$secret_name" --vault-name "$vault_name" --query "value" > "$raw_env"
  # Convert escaped newlines to real newlines and strip leading/trailing quotes
  sed 's/\\n/\n/g' "$raw_env" | sed '1s/^"//' | sed '$s/"$//' > "$fixed_env"
  rm -f "$raw_env"
  echo "Wrote $fixed_env"
done
