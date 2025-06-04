#!/bin/bash

# === Liste des ports à vérifier ===
PORTS=(8080 8081 8082 8083 8084 5432)

echo ">> Vérification des services sur les ports : ${PORTS[*]}"

# === Fonction pour vérifier un port ===
check_port() {
  local port=$1
  if sudo ss -tuln | grep -q ":$port"; then
    echo ">> Le service sur le port $port est actif."
  else
    echo "!! Aucun service actif sur le port $port."
  fi
}

# === Vérification de chaque port ===
for port in "${PORTS[@]}"; do
  check_port "$port"
done

echo ">> Vérification terminée."
