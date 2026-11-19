# TP 01 · Docker et Minikube

Construire l’image `hello-node:1.0` puis exécuter la même application sous Docker et Kubernetes.

## Prérequis

Docker en mode conteneurs Linux et Minikube avec le pilote Docker. Exécuter les commandes depuis ce dossier.

## Docker

```sh
docker build -t hello-node:1.0 .
docker run -d --name hello-node -p 127.0.0.1:8080:3000 hello-node:1.0
docker ps --filter name=hello-node
```

Ouvrir http://127.0.0.1:8080/ ou lancer `curl.exe -i http://127.0.0.1:8080/` sur Windows (`curl` sur Linux ou macOS). Si le port hôte est occupé, remplacer `8080` par `8081` dans la publication et dans l’URL. Après le test, exécuter `docker rm -f hello-node`. L’image locale reste disponible.

## Minikube

```sh
minikube start -p intro-docker --driver=docker
minikube -p intro-docker image load hello-node:1.0
minikube -p intro-docker image ls
minikube -p intro-docker kubectl -- apply -f deployment.yaml
minikube -p intro-docker kubectl -- rollout status deployment/hello-node
minikube -p intro-docker kubectl -- get 'pods,services'
minikube -p intro-docker service hello-node --url
```

Ouvrir l’URL affichée en laissant la commande active si elle ouvre un tunnel. Si l’URL ne répond pas, arrêter le tunnel et utiliser le transfert suivant. Ouvrir ensuite http://127.0.0.1:8080/ dans un deuxième terminal ou dans le navigateur.

```sh
minikube -p intro-docker kubectl -- port-forward service/hello-node 8080:8080
```

Si `8080` est occupé sur l’hôte, utiliser `8081:8080` et ouvrir http://127.0.0.1:8081/.

## Analyse

1. **Node.js** est fourni par l’image de base `node:24-alpine`. Le processus s’exécute dans le conteneur, donc le poste a seulement besoin de Docker et Minikube pour ce TP.
2. **Accès depuis le poste.** Docker publie le port hôte vers le port `3000` du conteneur. Kubernetes utilise un Service qui sélectionne les Pods `app: hello-node` et transfère son port `8080` vers leur port `3000`. Le NodePort `30007` appartient au nœud du cluster. Le tunnel Minikube ou le port-forward fournit un point d’accès depuis le poste.
3. **Cycle de vie.** Quand on supprime le conteneur lancé par `docker run`, il faut relancer cette commande pour le recréer. Kubernetes maintient la réplique déclarée dans le Deployment et recrée automatiquement un Pod si celui-ci est supprimé.
4. **État attendu.** Le Pod est `Ready` avec `1/1` conteneur prêt. Les deux déploiements répondent HTTP `200` et affichent `Hello, Docker and Minikube from Node.js!`.

## Résultats observés

| Vérification | Résultat |
| --- | --- |
| Docker sur `127.0.0.1:8080` | Port publié `8080 → 3000`, HTTP `200` |
| `minikube image ls` | `docker.io/library/hello-node:1.0` |
| Pod `hello-node-7dd869979d-5vbd7` | `Running`, `1/1` prêt |
| Service `hello-node` | `NodePort`, `8080:30007/TCP` |
| Minikube via le port-forward sur `127.0.0.1:8080` | HTTP `200`, corps identique à Docker |

Corps reçu dans les deux cas :

```text
Hello, Docker and Minikube from Node.js!
```

## Nettoyer

Arrêter le tunnel ou le transfert avec `Ctrl+C`, puis supprimer les objets de l’exercice et, s’il ne sert plus, son profil.

```sh
minikube -p intro-docker kubectl -- delete -f deployment.yaml
minikube delete -p intro-docker
```
