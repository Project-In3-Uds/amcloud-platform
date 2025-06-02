# amcloud-platform

Bienvenue sur **amcloud-platform**, la plateforme cloud modulaire conçue pour orchestrer, déployer et connecter de multiples services métier (IAM, gateway, reservation, billing, notification, invitation, config-server, etc.), de manière simple et scalable.

Ce README vous guide pour démarrer rapidement, comprendre la structure du dépôt, et intégrer de nouveaux services.

---

## Sommaire

- [Présentation](#présentation)
- [Architecture & Composants](#architecture--composants)
- [Structure du Dépôt](#structure-du-dépôt)
- [Installation & Démarrage Rapide](#installation--démarrage-rapide)
- [Utilisation des Scripts](#utilisation-des-scripts)
- [Gestion des Environnements](#gestion-des-environnements)
- [Accès aux Autres Services](#accès-aux-autres-services)
- [Déploiement Azure](#déploiement-azure)
- [Documentation & Wiki](#documentation--wiki)
- [FAQ](#faq)

---

## Présentation

**amcloud-platform** est une plateforme cloud multi-services intégrant :
- Un serveur d’identités (IAM),
- Une passerelle d’API (gateway),
- Des services métier (réservation, facturation, notifications, invitations),
- Une gestion centralisée de configuration,
- Un backend PostgreSQL.

Pensée pour la modularité, chaque service peut être déployé individuellement ou en mode full-stack.

---

## Architecture & Composants

Chaque service est conteneurisé (Docker) et orchestré via Docker Compose pour garantir portabilité et facilité de déploiement.

**Services principaux** :
- `iam` : Gestion des utilisateurs, authentification, autorisation.
- `gateway` : API Gateway centralisant l’accès à tous les services.
- `reservation`, `billing`, `notification`, `invitation` : Services métier indépendants.
- `config-server` : Centralisation de la configuration de tous les services.
- `postgres` : Base de données relationnelle.

**Intégration entre services :**
- Les services communiquent via REST (HTTP) à travers la gateway ou en direct selon les cas d’usage.
- Pour accéder à d'autres services depuis votre code, vous pouvez intégrer les endpoints via la gateway (ex: `http://gateway:8080/api/reservation`), ou directement par leur nom de service Docker (ex: `http://reservation:8081/` dans le réseau Docker).
- Des exemples de requêtes sont disponibles dans le fichier `restClient-Test` et la page [Pratiques API REST](./wiki/Pratiques-API-REST).

---

## Structure du Dépôt

| Dossier/Fichier           | Rôle                                                                                   |
|--------------------------|----------------------------------------------------------------------------------------|
| `scripts/`               | Scripts Bash pour déployer ou vérifier les services (`deploy-*.sh`, `check-services.sh`). |
| `docker/`                | Dockerfiles de build pour chaque service (un sous-dossier par service).                 |
| `env/`                   | Fichiers `.env.[service]` définissant les variables d’environnement de chaque service.  |
| `docker-compose.yml`     | Orchestration de tous les services pour le développement ou la CI/CD.                  |
| `restClient-Test`        | Fichier de requêtes de test pour chaque API/service.                                   |
| `...`                    | Code source, documentation, configurations additionnelles, etc.                        |

---

## Installation & Démarrage Rapide

1. **Prérequis** :  
   - [Docker](https://www.docker.com/) et [Docker Compose](https://docs.docker.com/compose/)
   - Cloner ce dépôt :  
     ```bash
     git clone https://github.com/<owner>/amcloud-platform.git
     cd amcloud-platform
     ```
2. **Configurer les environnements** :  
   Copier/modifier les fichiers `.env.[service]` dans le dossier `env/` selon vos besoins.
3. **Lancer la plateforme** :  
   ```bash
   docker-compose up -d
   ```
   Tous les services seront accessibles via la gateway ou leurs ports dédiés.
4. **Tester les services** :  
   Utilisez le fichier `restClient-Test` (compatible VSCode REST Client) pour tester les endpoints.

---

## Utilisation des Scripts

- **Déploiement d’un service spécifique** :
  ```bash
  ./scripts/deploy-iam.sh
  ```
- **Déploiement global de la plateforme** :
  ```bash
  ./scripts/deploy-all.sh
  ```
- **Vérification de l’état des services** :
  ```bash
  ./scripts/check-services.sh
  ```

_Détail complet dans la page [Scripts du Wiki](./wiki/Scripts)._

---

## Gestion des Environnements

Chaque service dispose d’un fichier `.env.[service]` dans `env/`, monté automatiquement dans le container correspondant.  
Adaptez les variables (ports, credentials, URLs) selon votre contexte.

_Détails et bonnes pratiques disponibles dans [Environnements (.env)](./wiki/Environnements-.-env-)._

---

## Accès aux Autres Services / Intégration

Pour accéder à un autre service depuis un service applicatif :
- **Via la Gateway** (centralisé, sécurisé, recommandé) :
  ```http
  http://gateway:8080/api/<service>/<endpoint>
  ```
- **Directement (dans le réseau Docker)** :
  ```http
  http://<service>:<port>/<endpoint>
  ```
Adaptez l’intégration selon la logique de votre microservice (voir les exemples dans `restClient-Test`).

---

## Déploiement Azure

Pour un déploiement sur Azure, reportez-vous à la page [Azure deployment](./wiki/Azure-deployment) du Wiki (scripts, pipelines, variables…).

---

## Documentation & Wiki

Retrouvez toute la documentation détaillée dans le [Wiki du projet](./wiki/Accueil) :

- Guides d’utilisation
- Architecture
- Intégration
- FAQ, bonnes pratiques, etc.

---

## FAQ

Consultez la page [FAQ](./wiki/FAQ) pour les questions et solutions courantes.

---

### Contribution

Les contributions sont les bienvenues ! Merci de consulter le Wiki et d’ouvrir des issues pour toute question ou suggestion.

---

© 2025 amcloud-platform
