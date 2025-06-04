#!/bin/bash

# === Paramètres de base ===
SERVICE_NAME=reservation
HOME=/home/debian
ENV_FILE="$HOME/amcloud-platform/env/.env.$SERVICE_NAME"
CLONE_DIR="/opt/amcloud/services/amcloud-$SERVICE_NAME"
REPO_URL="https://github.com/Project-In3-Uds/amcloud-$SERVICE_NAME.git"
PATH_TO_POM="backend"
BRANCH="dev"  

echo ">> Déploiement du service : $SERVICE_NAME sur la branche $BRANCH"

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

# === Étape 2 : Clonage du dépôt avec une branche spécifique ===
if [ -d "$CLONE_DIR/.git" ]; then
  echo ">> Le dépôt est déjà cloné. Passage à la branche $BRANCH..."
  cd "$CLONE_DIR" || exit 1
  git fetch origin
  git checkout "$BRANCH"
  git pull origin "$BRANCH"
else
  echo ">> Clonage du dépôt $REPO_URL (branche $BRANCH)..."
  git clone -b "$BRANCH" "https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/Project-In3-Uds/amcloud-$SERVICE_NAME.git" "$CLONE_DIR"
fi

# === Étape 3 : Génération du settings.xml Maven ===
M2_DIR="$HOME/.m2"
SETTINGS_FILE="$M2_DIR/settings.xml"
mkdir -p "$M2_DIR"

cat > "$SETTINGS_FILE" <<EOF
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>$GITHUB_USERNAME</username>
      <password>$GITHUB_TOKEN</password>
    </server>
  </servers>
</settings>
EOF

# === Étape 4 : Build Maven ===
if ls "$CLONE_DIR/$PATH_TO_POM/target/"*.jar 1> /dev/null 2>&1; then
  echo ">> Le projet est déjà compilé. Skipping build..."
else
  echo ">> Compilation du backend..."
  cd "$CLONE_DIR/$PATH_TO_POM" || exit 1
  mvn -s "$SETTINGS_FILE" clean install -DskipTests
fi

# === Étape 5 : Vérification et lancement de l'application ===
if pgrep -f "java -jar target/*.jar" > /dev/null; then
  echo ">> L'application tourne déjà. Skipping startup..."
else
  echo ">> Lancement de l'application..."
  cp "$ENV_FILE" "$CLONE_DIR/$PATH_TO_POM/.env"

  cd "$CLONE_DIR/$PATH_TO_POM" || exit 1
  nohup java -jar target/*.jar > "$CLONE_DIR/$SERVICE_NAME.log" 2>&1 &
fi

echo ">> Vérifiez $CLONE_DIR/$SERVICE_NAME.log pour le statut."
