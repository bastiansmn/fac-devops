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

Dans le déploiement via GitHub Actions, il a été nécessaire d'activer `export ANSIBLE_HOST_KEY_CHECKING=False` pour éviter à la commande `ssh` de demander une validation sur le terminal.

## Roles

La commande d'initialisation du rôle créé un dossier contenant un grand nombre de fichiers. Cependant, nous n'avons besoin que d'un fichier dans les répertoires `tasks` de chaque role.
On y trouve donc les différentes actions à effectuer, souvent simplifiées grâce aux modules Ansible.

## Front

La seule modification apportée au front est la modification de la variable `VUE_APP_API_URL`. On la change pour la valeur suivante :

```bash
VUE_APP_API_URL=bastian.somon.takima.cloud/api
```

Ainsi, lors d'un appel au backend, la requête retournera bien vers la VM. Cependant, en l'état, les requêtes ne sont pas bien dirigées. Il nous faut un reverse proxy.

## Reverse Proxy (RP)

Dans la configuration apache, il faut bien penser à activer tous les modules en décommentant les bonnes lignes (mod_proxy, mod_proxy_http, ...). On aura aussi besoin de mod_rewrite.

On créé un VirtualHost contenant les règles de routage :

```conf
<VirtualHost *:80>
    ServerName http://bastian.somon.takima.cloud/

    # Activer le module Rewrite pour ce VirtualHost
    RewriteEngine On

    # Load Balancer pour les requêtes /api/
    <Proxy "balancer://mycluster">
        BalancerMember http://tp1-back-1:8080
        BalancerMember http://tp1-back-2:8080
        ProxySet lbmethod=byrequests
    </Proxy>

    # Rediriger les requêtes /api/ vers le load balancer
    RewriteRule ^/api/(.*)$ balancer://mycluster/$1 [P,L]

    # Rediriger les requêtes /api/ vers le load balancer
    ProxyPass /api balancer://mycluster/
    ProxyPassReverse /api balancer://mycluster/

    # Rediriger les autres requêtes vers tp1-front:80
    ProxyPass / http://tp1-front:80/
    ProxyPassReverse / http://tp1-front:80/
</VirtualHost>
```

On spécifie le ServerName pour dire d'écouter tout le traffic entrant sur cette URL, puis on précise que les routes en / doivent être dirigées vers le front, et celles commencant par /api doivent être redirigées vers le back. 

À noter la mise en place du LoadBalancing via un `Proxy` contenant deux `BalancerMember`, en l’occurrence les deux instances déployées via Ansible. Le LoadBalancing est effectif via une répartition de charge équitable. Pas d'affinité de session car non nécessaire pour l'application, un des cas pouvant nécessité de l'affinité de session est par exemple lorsqu'il y a de la persistence en mémoire non partagée par les deux instances. Auquel cas on pourrait vouloir que nos requêtes aillent toujours vers l'instance contenant les données en mémoire. Ici, on a bien une application StateLess car aucune donnée n'est transitée pour permettre un LoadBalancing (exemple: cookie de session).

## Ansible Vault

Nous avons des variables à cacher (le mot de passe de la base de donnée). On va donc utiliser Ansible Vault pour le chiffrer. 

Tout d'abord on créé un fichier [vars/db.yml](ansible/vars/db.yml) contenant les variables à cacher. Ici j'ai ajouté aussi le user et le nom de la DB mais ceci n'est pas absolument nécessaire car c'est plutôt de la configuration que des secrets.

On peut ensuite exécuter la commande 

```bash
ansible-vault encrypt vars/db.yml
```

On doit spécifier le mot de passe (ici `titi`) et le fichier devient illisible.

Il est possible d'utiliser la commande `view` pour visualiser les variables, ou encore `decrypt` pour modifier le fichier après l'avoir déchiffré. 
On modifie ensuite le déploiement pour que le mot de passe soit écrit dans un fichier temporaire (via un secret GitHub). Dès lors, la commande `ansible-playbook` doit contenir l'argument `--vault-password-file=<fichier>`.

Maintenant, nous avons une CI/CD complètement fonctionnelle. On peut le tester en pushant une modification sur Git, les jobs se déclenchent bien et on peut vérifier le bon fonctionnement sur la VM [http://bastian.somon.takima.cloud/](http://bastian.somon.takima.cloud/).

Il a juste été nécessaire de créer un script sur la VM qui nettoyait le conteneurs Docker. En effet, l'image n'était pas toujours pull donc la modification de la CI non effective.

# Conclusion 

Nous avons donc maintenant un mini-projet fonctionnel et déployé avec de l'intégration et du déploiement continu. Il ne reste plus grand chose à améliorer si ce n'est du monitoring. Je n'ai pas eu le temps de déployer Grafan notamment car même la commande `ansible-galaxy` ne fonctionnait pas.
On pourrait aussi mettre en place un système de version pour éviter de taguer les images Docker par `latest` à chaque build.
Enfin, on pourrait améliorer le build pour que si on ne fait des changements que sur le dossier `frontend`, seul le build et le déploiement adéquat soit lancé. Cette problématique se retrouve dans tous les mono-repo.
