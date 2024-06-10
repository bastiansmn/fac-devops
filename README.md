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


