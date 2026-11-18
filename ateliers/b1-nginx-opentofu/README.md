# B1 · Déployer Nginx avec OpenTofu

Déployer un conteneur Nginx dans Docker, vérifier qu’une nouvelle planification ne propose aucun changement, puis retirer les ressources gérées.

## Prérequis

[OpenTofu](https://opentofu.org/docs/intro/install/), Docker en mode conteneurs Linux et le port TCP local `8080` libre. Exécuter les commandes depuis ce dossier. `docker version` doit afficher le client et le serveur.

Le fournisseur Docker reste en version `3.6.1`, comme dans le support. Sa source explicite est `registry.terraform.io/kreuzwerker/docker`. Le registre par défaut d’OpenTofu a rejeté la signature avec `unknown issuer`. Via le registre Terraform, OpenTofu 1.13.9 a reconnu la signature et signalé que la clé GPG avait expiré.

Sous Windows, si Docker Desktop utilise le contexte `desktop-linux`, PowerShell peut transmettre son point d’accès au fournisseur Docker pour la session courante.

```powershell
$env:DOCKER_HOST = docker context inspect desktop-linux --format '{{.Endpoints.docker.Host}}'
```

## Planifier et appliquer

```sh
tofu init
tofu fmt -check
tofu validate
tofu plan '-out=nginx.tfplan'
tofu show nginx.tfplan
tofu apply nginx.tfplan
tofu output -raw nginx_url
docker ps --filter name=infra-si-nginx
tofu state list
tofu plan -detailed-exitcode
```

La sortie `nginx_url` indique `http://127.0.0.1:8080`. Ouvrir cette adresse dans le navigateur ou vérifier depuis PowerShell avec `curl.exe -I http://127.0.0.1:8080/`. La réponse attendue est `200`. Si le port est occupé, adapter le port externe et la sortie dans `main.tf`, puis refaire le plan.

Après application, `tofu state list` doit afficher l’image et le conteneur. Le dernier plan doit annoncer `No changes` et sortir avec le code `0`. Le code `2` indique des changements et le code `1` une erreur.

### Résultats observés

| Vérification | Résultat |
| --- | --- |
| `tofu fmt -check` et `tofu validate` | Format et configuration valides |
| Premier plan puis application | `2 to add`, puis `2 added` |
| `tofu output -raw nginx_url` et requête HTTP | `http://127.0.0.1:8080`, réponse `200` |
| `tofu state list` | `docker_container.nginx` et `docker_image.nginx` |
| `tofu plan -detailed-exitcode` | `No changes`, code `0` |
| Plan de destruction puis application | `2 to destroy`, puis `2 destroyed`. Conteneur absent et image toujours dans Docker. |

## Nettoyer

```sh
tofu plan -destroy '-out=nginx-destroy.tfplan'
tofu show nginx-destroy.tfplan
tofu apply nginx-destroy.tfplan
docker ps -a --filter name=infra-si-nginx
docker image inspect nginx:1.28-alpine
```

Le conteneur doit disparaître. L’image reste dans le cache Docker grâce à `keep_locally`. Versionner `main.tf` et `.terraform.lock.hcl`. Les fichiers d’état et de plan restent locaux.
