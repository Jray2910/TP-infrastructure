# TP 02 · WebSolutions Inc.

Ce scénario utilise Ubuntu sous WSL comme environnement de test. Nginx reçoit la requête de santé, l’API Node.js vérifie PostgreSQL et renvoie la version déployée.

```text
curl dans Ubuntu → Nginx 127.0.0.1:8082
                         → API Docker 127.0.0.1:3002 → conteneur :3000
                           → PostgreSQL db:5432 sur websolutions-test
                             → volume websolutions-test-db
```

OpenTofu provisionne le réseau, les conteneurs et le stockage. Ansible installe le paquet Nginx sur Ubuntu, gère sa configuration et assure que le service tourne. PostgreSQL est joint par l’API depuis le réseau Docker, sans port publié. Le frontal du TP et le port publié de l’API écoutent sur la boucle locale d’Ubuntu.

## Prérequis

Utiliser Ubuntu avec systemd, Docker Engine, OpenTofu, `ansible-core`, Python 3 et `curl`. Le moteur Docker doit être accessible avec `sudo docker info` depuis le même système Linux. Le compte de contrôle doit pouvoir utiliser `sudo`. Copier le dossier du TP dans le système de fichiers Linux et y exécuter les commandes. Les ports locaux `3002` et `8082` doivent être disponibles.

```sh
umask 077
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

Renseigner le mot de passe de test dans ce fichier local. Le fournisseur Docker `3.6.1` utilise le même registre que [B1](../../ateliers/b1-nginx-opentofu/). Garder les états, plans et variables locales hors de Git.

## Pipeline local

```sh
bash pipeline.sh v1
```

Le runner Bash exécute les tests Node.js dans un conteneur. L’image est construite après leur réussite, taguée `websolutions-api:v1` et déployée par son identifiant Docker. Le runner applique le playbook, valide OpenTofu, affiche et enregistre le plan, applique ce plan puis exige une réponse de santé valide pour la version demandée. Dans Ubuntu, `curl -fsS http://127.0.0.1:8082/health` permet de répéter le contrôle.

Pour démontrer le blocage, modifier temporairement l’assertion HTTP `200` en `201` dans `app/server.test.js` et exécuter le pipeline avec un tag inédit. Il doit sortir dès les tests. Vérifier que le tag est absent avec `sudo docker image inspect websolutions-api:essai-echec`. Restaurer le test, puis relancer avec `v1`.

Pour revenir à une version déjà construite et testée sur le poste, exécuter `bash pipeline.sh v1 rollback`. Ce mode redéploie l’identifiant immuable associé au tag et rejoue le contrôle de santé. Conserver les images précédentes pendant la période de retour arrière.

## Contrôler la configuration et l’infrastructure

```sh
ansible-playbook -i config/inventory.ini config/site.yml --syntax-check
ansible-playbook -i config/inventory.ini config/site.yml
ansible-playbook -i config/inventory.ini config/site.yml
```

La seconde exécution doit renvoyer `changed=0`. Pour démontrer la correction d’un écart, ajouter un commentaire dans `/etc/nginx/conf.d/websolutions-test.conf`, rejouer le playbook puis vérifier que la copie correspond à `config/websolutions.conf`.

```sh
image_id=$(sudo docker image inspect --format '{{.Id}}' websolutions-api:v1)
sudo tofu -chdir=infra state list
sudo tofu -chdir=infra output
sudo env TF_VAR_api_image="$image_id" tofu -chdir=infra plan -detailed-exitcode
```

Le plan suivant doit afficher `No changes` et sortir avec le code `0`.

## Résultats observés

| Vérification | Résultat |
| --- | --- |
| Test volontairement cassé | Échec de l’assertion `200 !== 201`. La construction n’a pas démarré, le tag `essai-echec` était absent et le conteneur déjà déployé a conservé son identifiant. |
| Livraison après restauration du test | Deux tests réussis. Image `websolutions-api:v1`, identifiant initial abrégé `sha256:3a11bb61cdfe…`. Le premier plan a annoncé cinq ajouts. |
| Nouveau plan après application | `No changes`, code `0`. L’état contenait l’API, PostgreSQL, l’image PostgreSQL, le réseau et le volume. |
| Deuxième application Ansible | `ok=4 changed=0 failed=0`. |
| Correction du fichier après ajout d’un commentaire | `ok=6 changed=2 failed=0`. Ansible a restauré le fichier et rechargé Nginx. `cmp` a confirmé que les deux fichiers étaient identiques. |
| Contrôle final via Nginx | HTTP `200`, `{"status":"ok","database":"ok","version":"v1"}`. |
| Nettoyage | Cinq ressources supprimées après lecture du plan. La configuration Nginx dédiée a été retirée et Nginx a été rechargé. |

## Nettoyer

Le volume PostgreSQL contient les données. Sauvegarder celles à conserver avant destruction. Utiliser le tag effectivement déployé pour définir `image_id` dans les commandes ci-dessus.

```sh
sudo env TF_VAR_api_image="$image_id" tofu -chdir=infra plan -destroy -out=destroy.tfplan
sudo tofu -chdir=infra show destroy.tfplan
sudo tofu -chdir=infra apply destroy.tfplan
sudo rm /etc/nginx/conf.d/websolutions-test.conf
sudo nginx -t && sudo systemctl reload nginx
```

## Présentation et limites

Sur 10 à 15 minutes, présenter le besoin et le trajet HTTP, lire le plan et la sortie OpenTofu, montrer le second passage Ansible et la correction manuelle, puis démontrer le test bloquant et la livraison réussie. Terminer par le retour arrière et les choix de production.

UbuntuDev n’a pas répondu en SSH après son démarrage. Le test a donc été effectué dans Ubuntu WSL avec son propre moteur Docker. L’arrêt de WSL a interrompu les conteneurs entre deux commandes. La politique `unless-stopped` a été ajoutée, puis les preuves ont été relevées dans une même session WSL.

Le laboratoire partage un hôte Linux et un moteur Docker. En production, isoler les environnements et le runner, gérer les secrets hors des fichiers et de l’état local, conserver les images dans un registre et définir une stratégie de sauvegarde et de migration de la base.
