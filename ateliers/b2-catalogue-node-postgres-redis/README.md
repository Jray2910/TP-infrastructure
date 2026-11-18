# B2 · Catalogue Node.js, PostgreSQL et Redis

Déployer une API de catalogue. PostgreSQL conserve les produits et Redis garde une copie de la liste pendant 30 secondes. L’API seule publie un port sur le poste hôte.

## Prérequis et déploiement

Docker en mode conteneurs Linux, OpenTofu et le port local `3000` libre. Exécuter les commandes depuis ce dossier. Pour Docker Desktop sous Windows, reprendre le réglage de `DOCKER_HOST` décrit dans [B1](../b1-nginx-opentofu/README.md). Le fournisseur Docker `3.6.1` utilise le même registre qu’en B1.

```sh
docker build -t infra-si-catalogue-api:lab ./api
docker image inspect --format '{{.Id}}' infra-si-catalogue-api:lab
```

Copier `terraform.tfvars.example` vers `terraform.tfvars`. Reporter l’identifiant complet `sha256:…` affiché par Docker et choisir un mot de passe local de test. Garder `terraform.tfvars`, les états et les plans hors de Git.

```sh
tofu init
tofu fmt -check
tofu validate
tofu plan '-out=catalogue.tfplan'
tofu show catalogue.tfplan
tofu apply catalogue.tfplan
tofu output -raw api_url
```

## Vérifier la santé, le cache et la persistance

Depuis PowerShell, exécuter les deux requêtes `/products` à moins de 30 secondes d’intervalle sur une pile neuve. Sous Linux ou macOS, utiliser `curl`.

```powershell
curl.exe -fsS http://127.0.0.1:3000/health
curl.exe -fsS http://127.0.0.1:3000/products
curl.exe -fsS http://127.0.0.1:3000/products
```

`/health` doit indiquer `database: ok` et `redis: ok`. La première réponse de `/products` doit indiquer `source: postgresql`. La seconde doit contenir les mêmes produits et indiquer `source: redis`.

```powershell
docker exec infra-si-catalogue-db psql -U catalogue -d catalogue -c "INSERT INTO products VALUES (3, 'Ecran') ON CONFLICT DO NOTHING;"
docker restart infra-si-catalogue-db
Start-Sleep -Seconds 31
curl.exe -fsS http://127.0.0.1:3000/products
```

Après expiration du cache, la dernière réponse doit venir de PostgreSQL et inclure `Ecran`. Ce test confirme que les données survivent au redémarrage du conteneur. Recréer le conteneur en rattachant le même volume permettrait de vérifier leur persistance après remplacement du conteneur.

### Résultats observés

| Vérification | Résultat |
| --- | --- |
| `tofu apply` | 8 ressources créées |
| `GET /health` | HTTP `200`, `{"database":"ok","redis":"ok"}` |
| Deux appels à `GET /products` | `postgresql` puis `redis`, avec `Clavier` et `Souris` dans le même ordre |
| `GET /products` après redémarrage et expiration du cache | `postgresql`, avec le produit `3` (`Ecran`) toujours présent |
| Reconstruction après destruction | Santé OK et catalogue revenu aux deux produits initiaux sur des volumes neufs |

## Nettoyer

```sh
tofu plan -destroy '-out=catalogue-destroy.tfplan'
tofu show catalogue-destroy.tfplan
tofu apply catalogue-destroy.tfplan
docker ps -a --filter name=infra-si-catalogue
docker volume ls --filter name=infra-si-catalogue
```

Le nettoyage supprime les conteneurs, le réseau et les deux volumes, donc les données de l’atelier. L’image de l’API reste disponible. Pour vérifier la reconstruction, refaire le plan et l’appliquer sur des volumes neufs. Le catalogue doit alors contenir les deux produits initiaux.
