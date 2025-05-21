#!/bin/bash

# === Paramètres de base ===
SERVICE_NAME=gateway
HOME=/home/debian
ENV_FILE="$HOME/amcloud-platform/env/.env.$SERVICE_NAME"
CLONE_DIR="/opt/amcloud/services/amcloud-$SERVICE_NAME"
REPO_URL="https://github.com/Project-In3-Uds/amcloud-$SERVICE_NAME.git"
PATH_TO_POM="spring-cloud-gateway"

echo ">> Déploiement du service : $SERVICE_NAME"

# === Étape 1 : Sourcing de l'environnement ===
if [ ! -f "$ENV_FILE" ]; then
  echo "!! Fichier d'environnement introuvable : $ENV_FILE"
  exit 1
fi

echo ">> Chargement des variables d'environnement..."
set -a
source "$ENV_FILE"
set +a

# Vérification des variables critiques
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "!! Les variables GITHUB_USERNAME et GITHUB_TOKEN doivent être définies dans $ENV_FILE"
  exit 1
fi

# === Étape 2 : Clonage du dépôt ===
if [ -d "$CLONE_DIR/.git" ]; then
  echo ">> Le dépôt est déjà cloné. Skipping clone..."
else
  echo ">> Clonage du dépôt $REPO_URL..."
  git clone "https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/Project-In3-Uds/amcloud-$SERVICE_NAME.git" "$CLONE_DIR"
fi

# === Étape 3 : Build Maven ===
if ls "$CLONE_DIR/$PATH_TO_POM/target/"*.jar 1> /dev/null 2>&1; then
  echo ">> Le projet est déjà compilé. Skipping build..."
else
  echo ">> Compilation du backend..."
  cd "$CLONE_DIR/$PATH_TO_POM" || exit 1
  ./mvnw clean install -DskipTests
fi

# === Étape 4 : Vérification et lancement de l'application ===
if pgrep -f "java -jar target/*.jar" > /dev/null; then
  echo ">> L'application tourne déjà. Skipping startup..."
else
  echo ">> Lancement de l'application..."
  cp "$ENV_FILE" "$CLONE_DIR/$PATH_TO_POM/.env"

  cd "$CLONE_DIR/$PATH_TO_POM" || exit 1
  nohup java -jar target/*.jar > "$CLONE_DIR/$SERVICE_NAME.log" 2>&1 &
fi

echo ">> Service $SERVICE_NAME déployé et en cours d'exécution."
echo ">> Vérifiez $CLONE_DIR/$SERVICE_NAME.log pour le status..."
