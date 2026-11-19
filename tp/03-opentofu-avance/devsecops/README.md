# TP 03 · Plateforme DevSecOps

Gitea utilise SQLite. SonarQube contacte PostgreSQL sur `postgres:5432` au sein de `devops-net`. Jenkins conserve son état dans son propre volume.

## Démarrer

Prévoir environ 8 Gio disponibles pour Docker et des ports libres. Contrôler les valeurs sur le Linux qui héberge le moteur. `vm.max_map_count` doit atteindre 524288 et `fs.file-max` 131072. Ajuster uniquement les valeurs insuffisantes sur un moteur de laboratoire autorisé.

```sh
docker run --rm alpine:3.22 cat /proc/sys/vm/max_map_count /proc/sys/fs/file-max
umask 077
cp terraform.tfvars.example terraform.tfvars
```

Choisir un mot de passe local pour PostgreSQL dans `terraform.tfvars`, puis exécuter les commandes depuis ce dossier.

```sh
tofu init
tofu fmt -check
tofu validate
tofu plan '-out=devops.tfplan'
tofu show devops.tfplan
tofu apply devops.tfplan
docker ps -a --filter name=devops-
```

| Service | Accès depuis l’hôte Docker |
| --- | --- |
| Gitea | `http://127.0.0.1:3000/` |
| Jenkins | `http://127.0.0.1:8080/` |
| SonarQube | `http://127.0.0.1:9000/` |
| PostgreSQL | `127.0.0.1:5432` |

## Vérifier

Gitea utilise les paramètres SQLite du manifeste et démarre avec l’assistant d’installation désactivé. Créer le premier compte administrateur depuis Bash avec les commandes suivantes. Puis se connecter à Gitea, créer un dépôt de test, redémarrer Gitea avec `docker restart devops-gitea` et vérifier que le dépôt existe toujours.

```bash
read -rsp 'Mot de passe Gitea : ' gitea_password
echo
docker exec --user git devops-gitea gitea admin user create \
  --admin --username labadmin --email labadmin@example.invalid \
  --password "$gitea_password" --must-change-password=false
unset gitea_password
```

Ouvrir Jenkins et suivre l’assistant si nécessaire. Son code d’amorçage est accessible par `docker exec devops-jenkins cat /var/jenkins_home/secrets/initialAdminPassword`. Le saisir localement.

```sh
curl -fsS http://127.0.0.1:9000/api/system/status
docker exec devops-postgres pg_isready -h 127.0.0.1 -U sonar -d sonar
tofu plan -detailed-exitcode
```

SonarQube doit passer à `UP`, PostgreSQL accepter les connexions et le plan afficher `No changes`. Si l’interface SonarQube demande le compte d’amorçage, changer le mot de passe dès la première connexion.

### Résultats observés

| Vérification | Résultat |
| --- | --- |
| Limites Linux vues depuis Docker | `vm.max_map_count=1048576`, `fs.file-max=9223372036854775807` |
| `tofu validate` et `tofu apply` | Configuration valide, 15 ressources créées |
| `pg_isready` | PostgreSQL accepte les connexions |
| Gitea `/api/v1/version` et test du dépôt | Version `1.25.5`, dépôt privé `labadmin/temoin-tp03` retrouvé après redémarrage |
| Jenkins `/login` | HTTP `200`, fichier d’amorçage présent. Validation au stade de l’assistant. |
| SonarQube `/api/system/status` | `UP`, version `26.11.0.134175` |
| `tofu plan -detailed-exitcode` | `No changes`, code `0` |

Digests des images utilisées :

```text
gitea/gitea@sha256:f846d26a4fc389c5806a580a765e00bfdd1fd181e6f2060da98ea2669d914472
jenkins/jenkins@sha256:74401de6a6f92e1afe1b02d1c8e3d0c33f263bfb5275dd8813f9150355f2367b
sonarqube@sha256:65541accbdb92e27fe770fc6ba99988a3dd5a0c71ffafd67f88abfad366996fa
postgres@sha256:1d5b02d3a9941fbd52437db4107f8c52d6297dac553ca1e5c299ebb3756b4857
```

## Nettoyer

Sauvegarder les données utiles. Le plan de destruction inclut les volumes et le dépôt de test.

```sh
tofu plan -destroy '-out=devops-destroy.tfplan'
tofu show devops-destroy.tfplan
tofu apply devops-destroy.tfplan
docker ps -a --filter name=devops-
```

Le plan de destruction a annoncé 15 suppressions. Après application, aucun conteneur DevSecOps ne restait.
