#!/bin/bash

# ==============================================================================
# Script de déploiement automatique pour PostgreSQL et l'installeur Java
# ==============================================================================

# === Paramètres de base ===
SERVICE_NAME=postgres # Nom du service (ex: postgres)
SYSTEM_USER=amcloud_postgres # Nouvel utilisateur système dédié au service PostgreSQL
SYSTEM_HOME="/home/$SYSTEM_USER" # Répertoire home de l'utilisateur système
HOME=/home/debian     # Répertoire d'accueil de l'utilisateur exécutant ce script (pour le fichier .env)
# Chemin vers le fichier .env spécifique à PostgreSQL
ENV_FILE="$HOME/amcloud-platform/env/.env.$SERVICE_NAME"
# Répertoire où le dépôt 'amcloud-postgres' sera cloné
CLONE_DIR="/opt/amcloud/services/amcloud-$SERVICE_NAME"
# URL du dépôt Git contenant le projet 'amcloud-postgres' (le nom du dépôt doit correspondre au SERVICE_NAME)
REPO_URL="https://github.com/Project-In3-Uds/amcloud-$SERVICE_NAME.git"
# Chemin relatif vers le module Maven de l'installeur PostgreSQL dans le dépôt cloné
PATH_TO_POM="postgres" # Assurez-vous que c'est le nom du répertoire du module Maven

echo ">> Démarrage du déploiement du service : $SERVICE_NAME"

# === Étape 0 : Gérer l'utilisateur système et configurer sudoers ===
echo ">> Gestion de l'utilisateur système $SYSTEM_USER..."
if id "$SYSTEM_USER" &>/dev/null; then
  echo ">> L'utilisateur $SYSTEM_USER existe déjà. Suppression et recréation..."
  # Supprimer l'utilisateur et son répertoire home
  sudo userdel -r "$SYSTEM_USER" || { echo "!! Erreur lors de la suppression de l'utilisateur $SYSTEM_USER."; exit 1; }
  # Supprimer le fichier sudoers dédié si il existe
  sudo rm -f /etc/sudoers.d/$SYSTEM_USER
  echo ">> L'utilisateur $SYSTEM_USER a été supprimé."
else
  echo ">> L'utilisateur $SYSTEM_USER n'existe pas. Création..."
fi

echo ">> Création de l'utilisateur système $SYSTEM_USER avec répertoire home $SYSTEM_HOME..."
sudo useradd -m -d "$SYSTEM_HOME" -s /bin/bash "$SYSTEM_USER" || { echo "!! Erreur lors de la création de l'utilisateur $SYSTEM_USER."; exit 1; }

echo ">> Ajout de $SYSTEM_USER à sudoers pour NOPASSWD..."
# Crée un fichier sudoers dédié pour cet utilisateur
echo "$SYSTEM_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$SYSTEM_USER > /dev/null || { echo "!! Erreur lors de l'ajout à sudoers."; exit 1; }
sudo chmod 0440 /etc/sudoers.d/$SYSTEM_USER || { echo "!! Erreur lors de la modification des permissions sudoers."; exit 1; }
echo ">> L'utilisateur $SYSTEM_USER a été créé et configuré dans sudoers."


# === Assurer que le répertoire home de l'utilisateur système est accessible en écriture ===
# Ceci est crucial si l'utilisateur existait déjà ou si useradd n'a pas correctement défini les permissions.
echo ">> Vérification et ajustement des permissions du répertoire home de $SYSTEM_USER ($SYSTEM_HOME)..."
if [ ! -d "$SYSTEM_HOME" ]; then
    echo "!! Le répertoire home de l'utilisateur $SYSTEM_USER ($SYSTEM_HOME) est manquant. Tentative de création..."
    sudo mkdir -p "$SYSTEM_HOME" || { echo "!! Erreur: Impossible de créer le répertoire home $SYSTEM_HOME."; exit 1; }
fi
# S'assurer que le propriétaire est correct et que les permissions sont suffisantes
sudo chown "$SYSTEM_USER":"$SYSTEM_USER" "$SYSTEM_HOME" || { echo "!! Erreur: Impossible de changer le propriétaire de $SYSTEM_HOME."; exit 1; }
sudo chmod 700 "$SYSTEM_HOME" || { echo "!! Erreur: Impossible de définir les permissions de $SYSTEM_HOME."; exit 1; }
echo ">> Répertoire home de $SYSTEM_USER ($SYSTEM_HOME) vérifié et permissions ajustées."


# === Étape 1 : Sourcing de l'environnement ===
if [ ! -f "$ENV_FILE" ]; then
  echo "!! Fichier d'environnement introuvable : $ENV_FILE"
  echo "Veuillez créer ce fichier avec les variables POSTGRES_USER, POSTGRES_PASSWORD, MAIN_DB_NAME, BILLING_DB_NAME, GITHUB_USERNAME, GITHUB_TOKEN."
  exit 1
fi

echo ">> Chargement des variables d'environnement depuis $ENV_FILE..."
# Utilisation de 'set -a' pour exporter toutes les variables définies dans le fichier
set -a
source "$ENV_FILE"
set +a

# Vérification des variables critiques pour GitHub et PostgreSQL
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "!! Les variables GITHUB_USERNAME et GITHUB_TOKEN doivent être définies dans $ENV_FILE"
  exit 1
fi
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ] || [ -z "$MAIN_DB_NAME" ] || [ -z "$BILLING_DB_NAME" ]; then
  echo "!! Les variables POSTGRES_USER, POSTGRES_PASSWORD, MAIN_DB_NAME, BILLING_DB_NAME doivent être définies dans $ENV_FILE"
  exit 1
fi

# === Étape 2 : Clonage ou mise à jour du dépôt ===
echo ">> Clonage ou mise à jour du dépôt $REPO_URL dans $CLONE_DIR..."
if [ ! -d "$CLONE_DIR/.git" ]; then
  echo "Clonage du dépôt..."
  # Clonage avec authentification GitHub
  sudo git clone "https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/Project-In3-Uds/amcloud-$SERVICE_NAME.git" "$CLONE_DIR" || { echo "!! Erreur lors du clonage du dépôt."; exit 1; }
else
  echo "Le dépôt est déjà cloné."
fi

# Assurer la propriété correcte et configurer safe.directory avant toute opération Git
echo ">> Ajustement des permissions et configuration Git safe.directory pour $CLONE_DIR..."
sudo chown -R "$SYSTEM_USER":"$SYSTEM_USER" "$CLONE_DIR" || { echo "!! Erreur lors du changement de propriétaire du dépôt."; exit 1; }
# Exécuter git config en tant que SYSTEM_USER depuis son répertoire HOME
sudo -u "$SYSTEM_USER" bash -c "export HOME='$SYSTEM_HOME' && cd '$SYSTEM_HOME' && git config --global --add safe.directory '$CLONE_DIR'" || { echo "!! Erreur lors de l'ajout du répertoire au safe.directory Git."; exit 1; }

# Maintenant, effectuer le pull si le dépôt était déjà cloné
if [ -d "$CLONE_DIR/.git" ]; then
  echo "Mise à jour du dépôt..."
  # Supprimer le fichier .env local avant le pull pour éviter les conflits
  echo ">> Suppression du fichier .env local dans le dépôt pour éviter les conflits de fusion..."
  sudo -u "$SYSTEM_USER" rm -f "$CLONE_DIR/$PATH_TO_POM/.env" || { echo "!! Avertissement: Impossible de supprimer le fichier .env local. Cela pourrait causer des conflits."; }
  sudo -u "$SYSTEM_USER" git -C "$CLONE_DIR" pull || { echo "!! Erreur lors de la mise à jour du dépôt."; exit 1; }
fi

# === Étape 3 : Compilation du projet ===
echo ">> Compilation du module PostgresInstaller..."
INSTALLER_MODULE_PATH="$CLONE_DIR/$PATH_TO_POM"
if [ ! -d "$INSTALLER_MODULE_PATH" ]; then
    echo "!! Le chemin du module PostgresInstaller est introuvable : $INSTALLER_MODULE_PATH"
    exit 1
fi

# Trouver le JAR compilé (le JAR principal, pas le "original")
# Utilise un filtre plus spécifique pour '-SNAPSHOT.jar' car c'est souvent le JAR exécutable
# Cette variable sera utilisée pour vérifier si le JAR existe déjà
COMPILED_JAR=$(find "$INSTALLER_MODULE_PATH/target" -name '*-SNAPSHOT.jar' | head -n 1)

# Vérifier si le JAR est déjà compilé
if [ -f "$COMPILED_JAR" ]; then
  echo ">> Le projet est déjà compilé (JAR trouvé: $COMPILED_JAR). Skip la compilation."
else
  echo ">> Compilation du backend (PostgresInstaller) avec Maven..."
  # Exécute la compilation en tant que SYSTEM_USER, en s'assurant que HOME est défini pour mvnw
  sudo -u "$SYSTEM_USER" bash -c "export HOME='$SYSTEM_HOME' && cd '$INSTALLER_MODULE_PATH' && ./mvnw clean install -DskipTests" || { echo "!! Erreur lors de la compilation Maven."; exit 1; }
fi


# === Étape 4 : Lancement de l'application ===
echo ">> Lancement de l'installeur PostgreSQL..."

# Copie du fichier .env dans le répertoire du JAR pour que dotenv-java le trouve
echo ">> Copie du fichier .env dans le répertoire de l'installeur pour l'exécution..."
cp "$ENV_FILE" "$INSTALLER_MODULE_PATH/.env" || { echo "!! Erreur lors de la copie du fichier .env."; exit 1; }
sudo chown "$SYSTEM_USER":"$SYSTEM_USER" "$INSTALLER_MODULE_PATH/.env" || { echo "!! Erreur lors du changement de propriétaire du fichier .env."; exit 1; }

# Trouver le JAR compilé (le JAR principal, pas le "original")
# IMPORTANT : Cette variable doit être re-définie ici au cas où la compilation vient d'avoir lieu.
INSTALLER_JAR=$(find "$INSTALLER_MODULE_PATH/target" -name '*-SNAPSHOT.jar' | head -n 1)

if [ -z "$INSTALLER_JAR" ]; then
    echo "!! JAR de l'installeur introuvable après la compilation. Impossible de continuer."
    exit 1
fi

# Définir le chemin du fichier de log
LOG_FILE="$CLONE_DIR/$SERVICE_NAME.log"
echo "La sortie de l'installeur sera redirigée vers : $LOG_FILE"

# Vérification si l'application tourne déjà (basé sur le nom du JAR)
# Note: pgrep peut être imprécis, mais suit le template.
if pgrep -f "java -jar $INSTALLER_JAR" > /dev/null; then
  echo ">> L'application tourne déjà. Skip le démarrage."
else
  echo ">> Lancement de l'application (PostgresInstaller) en arrière-plan..."
  # Exécute le JAR en tant que SYSTEM_USER, en s'assurant que HOME est défini
  sudo -u "$SYSTEM_USER" bash -c "export HOME='$SYSTEM_HOME' && cd '$INSTALLER_MODULE_PATH' && nohup java -jar '$INSTALLER_JAR' > '$LOG_FILE' 2>&1 &" || { echo "!! Erreur lors du lancement de l'installeur Java."; exit 1; }
fi

echo ">> Le processus d'installation/configuration de PostgreSQL est lancé en arrière-plan."
echo ">> Vérifiez $LOG_FILE pour le statut et les informations de connexion."
echo ">> Le déploiement du service $SERVICE_NAME est terminé."
