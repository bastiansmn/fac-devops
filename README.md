# Rendu

# TP1

## 1. DB

Dans le répertoire [`db`](./db/), on trouve le Dockerfile permettant le build de l'image ainsi qu'un fichier [`run.sh`](./db/run.sh) pour lancer `adminer` et `postgres`.

Avant de lancer ce script, il faut spécifier la variable `POSTGRES_PASSWORD=<password>`. Ce mot de passe sera à utiliser lors de la connexion.

Dans le script de démarrage, on trouve la création du network dédié. Ensuite on stoppe les conteneurs n'ayants pas été éteints. On note l'utilisation de l'option `--rm` lors du run pour supprimer automatiquement le conteneur.

On utilise un volume (dossier local [`./data`](./db/data/)) afin de persister les données après un redémarrage du conteneur. Le conteneur redémarrera donc avec les données de l'exécution précédente.

Ici, il n'est pas nécessaire d'exposer la DB sur le port `5433`, c'est principalement un confort afin d'utiliser les commandes type `psql`.

J'ai créé un fichier [`docker-compose.yml`](./db/docker-compose.yml) afin de simplifier la création des conteneurs. On peut le lancer via la commande `docker compose up`. Il faut bien penser à utiliser la commande `export POSTGRES_PASSWORD=<password>` avant de lancer le script.

Dès lors, on peut naviguer vers [`localhost:8080`](http://localhost:8080) pour se connecter via `adminer`. Les identifiants sont donc :

Serveur : `tp1-db-postgres` <br/>
Utilisateur : `usr` <br/>
Mot de passe : `<password>` <br/>
Base de donnée : `db` <br/>

## 2. Backend

### Basics

Ici, on se place dans le répertoire [`backend`](./backend/). Le fichier [`Dockerfile`](./backend/Dockerfile) contient les instructions pour construire l'image. On utilise un JRE en Java 21 (car c'est la version courante sur ma machine). En effet, étant donné que le build est sur ma machine, il est nécessaire que la version du run (donc la version de l'image de base) soit la même que celle de la compilation.

Pour la partie basique (Hello World), le fichier [`run.sh`](./backend/run.sh) contient les instructions de build et de run. L'exécution de ce dernier affiche bien `Hello World !`.

### Multi-stages

Ici, on utilise un "multi-stage build" pour que la compilation et le run soit écrit dans le même fichier ([`Dockerfile.multistage`](./backend/Dockerfile.multistage)). On utilise cette technique pour deux raisons : 
* Unifier les 2 phases (compilation et run) pour s'assurer que les deux coincident bien (par rapport à la version de Java par exemple).
* Réduire la taille de l'image finale. En effet, les fichiers produits lors de la phase de build ne seront pas dans l'image finale. On aura unifié les phases, sans alourdir inutilement notre image.

En lançant le script [`run-multistage.sh`](./backend/run-multistage.sh), l'application SpringBoot se lance correctement et en allant visiter [localhost:8080](http://localhost:8080), on visualise bien le JSON retourné. Un rechargement de la page incrémente correctement le compteur.

### Backend API

Pour cette sous-partie, on se place dans le répertoire [`backend-api`](./backend-api/).
Pour réaliser la tâche demandée, nous allons utiliser une fonctionnalité de Spring permettant de surcharger la configuration du fichier Yaml via des variables d'environnements.

Ici, nous pouvons soit utiliser le network créé précédemment pour la base de donnée, mais les standards de sécurité ([https://cyber.gouv.fr/publications/recommandations-de-securite-relatives-au-deploiement-de-conteneurs-docker](https://cyber.gouv.fr/publications/recommandations-de-securite-relatives-au-deploiement-de-conteneurs-docker), règle n°5 de la sécurité des conteneurs Docker) impliquent de créer un nouveau network pour la communication entre les deux éléments. 

On créé alors un network différent du précédent, dans mon cas `backend-network`. De même que pour la DB, la variable `POSTGRES_PASSWORD` doit être mise à la même valeur que celle de la DB.

## 3. Http server

# TP2

## Setup GitHub Actions

Nous utilisons la commande `mvn clean verify` pour tester notre code. Celle-ci démarre les "testcontainers", permettant de tester notre application. Ils permettent de "mocker" les services de notre applications tels que la base de donnée, etc. De plus, ils permettent une isolation des tests pour une meilleure reproductibilité et un meilleur parallélisme.

J'ai eu un problème lors de la configuration car j'utilisais Rancher Desktop. En passant sur Docker Desktop, les tests ont été concluants.

Dans nos fichiers `.yml` de GitHub Actions, nous allons utiliser la ["login-action"](https://github.com/docker/login-action) pour avoir une certaine cohérence dans l'utilisation des actions externes.

Les secrets ont bien été initialisés dans l'onglet Settings > Secrets and variables > Actions > Repository secrets. 

Pour commencer, nous allons préciser que le push sur Docker Hub ne s'effectue que sur la branche `main` via l'attribut : `push: ${{ github.ref == 'refs/heads/main' }}`. Nous changerons cette méthode plus tard.

## Setup SonarCloud

Après avoir créé un compte connecté à mon identifiant GitHub, j'ai créé un projet lié à des GitHub Actions depuis l'onglet SonarCloud. Ce dernier m'a très simplement donné la configuration nécessaire à ajouter dans mon fichier pom.xml et à ajouter dans mes actions GitHub. On y remarque un bloc supplémentaire : 

```yaml
#### CONFIGURATION BY SONAR ####
      - name: Cache SonarCloud packages
        uses: actions/cache@v3
        with:
          path: ~/.sonar/cache
          key: ${{ runner.os }}-sonar
          restore-keys: ${{ runner.os }}-sonar
      - name: Cache Maven packages
        uses: actions/cache@v3
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
          restore-keys: ${{ runner.os }}-m2
      #### ENF OF CONFIGURATION BY SONAR ####
```

Ici, on met en cache certains artefacts afin de réduire le temps de build.

Après avoir ajouté le `SONAR_TOKEN` aux secrets, la CI/CD est maintenant complètement fonctionnelle.

## Split pipelines

Il ne reste plus qu'à créer deux pipelines distinctes, une pour la partie validation ([ci.yml](./.github/workflows/ci.yml)) et une autre pour la partie déploiement ([cd.yml](./.github/workflows/cd.yml)).

Il faut préciser que le déploiement ne doit s'exécuter que lorsque l'exécution de la CI est réussie et uniquement sur la branche `main`. Ainsi, on doit modifier la clé `on:` :

```yaml
on:
  workflow_run:
    workflows:
      - CI devops 2024
    types:
      - completed
    branches:
      - main
```

La CI quand a elle conserve : 

```yaml
on: 
  push:
    branches:
      - main
      - develop
```

On se rend vite compte qu'un push sur la branche `main` lance le workflow d'intégration puis le workflow de déploiement si l'integration réussie. Cependant, un push sur la branche `develop` ne lance que le workflow d'intégration.

On peut confirmer que les images Docker sont bien présentes et mises à jour sur la plateforme Docker Hub.

À noter que les images sont toutes tagués `latest`. Il serait idéal de les taguer avec le numéro de commit git par exemple, sinon on perd tout l’intérêt d'utiliser un VCS. 

# TP3

## Inventories

Dans le fichier [setup.yml](ansible/inventories/setup.yml), on spécifie le chemin de la clé privée RSA. On utilise un chemin relatif au dossier `$HOME`. En exécutant la commande `ansible all -i inventories/setup.yml -m ping`, on obtient bien le statut 'SUCCESS'.

## Playbook

On commence par initialiser le playbook avec les commandes de bases pour initialiser Docker. Ensuite, pour mieux factoriser le code, on va initialiser des "roles" pour chaque action principale (initialisation de Docker, création des networks, DB, ...).

## Roles

La commande d'initialisation du rôle créé un dossier contenant un grand nombre de fichiers. Cependant, nous n'avons 
