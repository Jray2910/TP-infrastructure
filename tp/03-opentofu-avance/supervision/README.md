# TP 03 · Supervision locale

Prometheus interroge `/metrics` toutes les cinq secondes. Alloy lit le journal de Node.js et l’envoie à Loki. Grafana reçoit automatiquement les deux sources et le tableau de bord **Application Node.js**.

## Démarrer

Arrêter la pile DevSecOps si elle utilise les mêmes ports. Depuis ce dossier, copier l’exemple de variables et choisir un mot de passe Grafana de laboratoire.

```sh
umask 077
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu fmt -check
tofu validate
tofu plan '-out=monitoring.tfplan'
tofu show monitoring.tfplan
tofu apply monitoring.tfplan
docker ps -a --filter name=monitoring-
```

## Générer et retrouver les signaux

```sh
curl -fsS http://127.0.0.1:8080/
curl -fsS http://127.0.0.1:8080/
curl -fsS http://127.0.0.1:8080/
curl -fsS http://127.0.0.1:8080/metrics
curl -fsS http://127.0.0.1:3100/ready
```

Ouvrir les cibles Prometheus sur `http://127.0.0.1:9090/targets`. Le job `node` doit être `UP`. Dans Grafana sur `http://127.0.0.1:3000/`, se connecter avec `admin` et le mot de passe local. Ouvrir le tableau de bord **Application Node.js**, ou interroger `up{job="node"}` et `http_requests_total{job="node"}` avec Prometheus et `{job="node"}` avec Loki dans **Explore**.

Le compteur est cumulatif et repart de zéro si Node.js redémarre. Loki montre les entrées de la fenêtre affichée. Sur un démarrage neuf, trois requêtes à `/` donnent un compteur de trois et trois journaux `status: 200` une fois les données collectées. Les scrapes de `/metrics` ne génèrent aucun de ces événements.

### Résultats observés

| Vérification | Résultat |
| --- | --- |
| `tofu validate` et `tofu apply` | Configuration valide, 16 ressources créées |
| `/metrics` après trois requêtes à `/` | `http_requests_total 3` |
| API des cibles Prometheus | Cible `node` en état `up` |
| Requête Prometheus via la source Grafana | `http_requests_total{job="node"}` vaut `3` |
| Requête Loki via la source Grafana | Trois journaux de la route `/` avec `status: 200` |
| Tableau de bord provisionné dans Grafana | Deux panneaux, compteur et journaux |

Exemple renvoyé par la source Loki de Grafana :

```json
{"time":"2026-11-19T12:47:19.640Z","path":"/","status":200}
```

## Nettoyer

Sauvegarder les données utiles. La destruction supprime les volumes de journaux, de métriques et de configuration locale.

```sh
tofu plan -destroy '-out=monitoring-destroy.tfplan'
tofu show monitoring-destroy.tfplan
tofu apply monitoring-destroy.tfplan
docker ps -a --filter name=monitoring-
```

Le plan de destruction a annoncé 16 suppressions. Après application, aucun conteneur de supervision ne restait.
