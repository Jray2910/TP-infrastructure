# A5 · Déployer Nginx avec Minikube

Déployer Nginx sur un cluster Kubernetes local et vérifier que le Deployment recrée un Pod supprimé.

## Prérequis

Docker en mode conteneurs Linux, [Minikube](https://minikube.sigs.k8s.io/docs/start/) et le port TCP local `8090` libre. Exécuter les commandes depuis ce dossier.

## Déployer et tester

```sh
minikube start -p infra-si --driver=docker
minikube -p infra-si kubectl -- get nodes
minikube -p infra-si kubectl -- apply -f nginx.yaml
minikube -p infra-si kubectl -- rollout status deployment/nginx --timeout=120s
minikube -p infra-si kubectl -- get 'pods,services'
minikube -p infra-si kubectl -- port-forward service/nginx 8090:80
```

Garder la dernière commande active et ouvrir `http://127.0.0.1:8090/` dans le navigateur. Sous PowerShell, on peut aussi tester avec `curl.exe -I http://127.0.0.1:8090/`. La réponse attendue est `HTTP 200`.

## Vérifier le remplacement du Pod

Arrêter le port-forward avec `Ctrl+C`. Relever le nom du Pod, remplacer `NOM_DU_POD` dans la commande et vérifier qu’un autre Pod devient prêt.

```sh
minikube -p infra-si kubectl -- get pods -l app=nginx
minikube -p infra-si kubectl -- delete pod NOM_DU_POD
minikube -p infra-si kubectl -- wait --for=condition=Ready pod -l app=nginx --timeout=120s
minikube -p infra-si kubectl -- get pods -l app=nginx
```

Le Deployment conserve une réplique via son ReplicaSet. Le Service sélectionne le Pod de remplacement grâce au label `app: nginx`. Relancer le port-forward et vérifier à nouveau la réponse HTTP.

### Résultats observés

Test effectué avec Minikube `v1.39.0` et Kubernetes `v1.37.0` sur Docker Desktop.

| Vérification | Résultat |
| --- | --- |
| `get nodes` | `infra-si` dans l’état `Ready` |
| `get 'pods,services'` après déploiement | Pod `nginx-7455c48846-p56hd` en `Running` (`1/1`), service `nginx` de type `ClusterIP` sur `80/TCP` |
| HTTP via le port-forward avant suppression | `200` |
| `wait` puis `get pods` après suppression | Nouveau Pod `nginx-7455c48846-7xwdz` en `Running` (`1/1`) |
| HTTP via un nouveau port-forward | `200` |

## Nettoyer

Arrêter le port-forward avec `Ctrl+C`, puis supprimer le profil dédié avec `minikube delete -p infra-si`.

Après le test, `minikube delete -p infra-si` a supprimé le profil et son conteneur Docker.
