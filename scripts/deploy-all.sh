#!/bin/bash

# === Paramètres de base ===
SERVICES=("config-server" "gateway" "postgres" "iam" "reservation" "billing" "notification" "invitation")
SCRIPTS_DIR="/home/debian/amcloud-platform/scripts"

echo ">> Déploiement de tous les services : ${SERVICES[*]}"

# === Fonction pour déployer un service ===
deploy_service() {
  local service=$1
  local script="$SCRIPTS_DIR/deploy-$service.sh"

  echo ">> Déploiement du service : $service"
  if [ -f "$script" ]; then
    bash "$script"
    if [ $? -ne 0 ]; then
      echo "!! Échec du déploiement du service : $service"
      exit 1
    fi
  else
    echo "!! Script introuvable pour le service : $service ($script)"
    exit 1
  fi
}

# === Déploiement de tous les services ===
for service in "${SERVICES[@]}"; do
  deploy_service "$service"
done

echo ">> Tous les services ont été déployés avec succès."