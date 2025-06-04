#!/bin/bash

set -e

echo ">> Mise à jour du système"
sudo apt update && sudo apt upgrade -y

echo ">> Installation de Java 17 (OpenJDK)"
sudo apt install -y openjdk-17-jdk
java -version

echo ">> Installation de Git"
sudo apt install -y git
git --version

echo ">> Installation de Maven"
sudo apt install -y maven
mvn -version

echo ">> Installation d'utilitaires (curl, wget, unzip)"
sudo apt install -y curl wget unzip

read -p "Souhaitez-vous installer Node.js (y/n)? " install_node
if [[ "$install_node" == "y" ]]; then
  echo ">> Installation de Node.js (v20)"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  node -v && npm -v
fi

read -p "Souhaitez-vous installer Docker (y/n)? " install_docker
if [[ "$install_docker" == "y" ]]; then
  echo ">> Installation de Docker"
  sudo apt install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  docker --version
fi


echo ">> Installation terminée avec succès."
