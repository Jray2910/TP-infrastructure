# A1 · MongoDB avec Docker

L’atelier vérifie qu’un document MongoDB reste disponible après le remplacement du conteneur grâce au volume nommé `mongo-data`.

## Prérequis

Docker en mode conteneurs Linux, Docker Compose et le port local `27017` libre. Lancez les commandes depuis ce dossier. Les identifiants `root` et `example` sont ceux du laboratoire et le port est publié sur `127.0.0.1`.

## Démarrer et écrire un document

```sh
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose exec mongo mongosh -u root -p example --authenticationDatabase admin
```

Si MongoDB est encore en cours d’initialisation, relancez la dernière commande après quelques secondes. Dans `mongosh`, exécutez les lignes suivantes.

```javascript
use support
db.tickets.updateOne(
  { code: "T-101" },
  { $set: { sujet: "Acces au portail" } },
  { upsert: true }
)
db.tickets.findOne({ code: "T-101" })
exit
```

## Vérifier la persistance

```sh
docker compose ps -q mongo
docker compose down
docker compose up -d
docker compose ps -q mongo
docker compose exec mongo mongosh -u root -p example --authenticationDatabase admin
```

```javascript
use support
db.tickets.findOne({ code: "T-101" })
exit
```

Les deux identifiants de conteneur doivent différer. La requête doit toujours retrouver `T-101` avec le sujet `Acces au portail`.

### Résultat observé

`docker compose config --quiet` a terminé avec le code 0. Après `down` puis `up -d`, `docker compose ps -q mongo` est passé de `5bfd57598721` à `0271f3ca8e5a` (identifiants abrégés). La recherche de `T-101` dans `support.tickets` a renvoyé le même document avant et après la recréation, avec la projection sans `_id` ci-dessous.

```json
{"code":"T-101","sujet":"Acces au portail"}
```

## Nettoyer

`docker compose down` arrête et retire le conteneur en conservant les données. Pour remettre volontairement l’atelier à zéro, `docker compose down -v` supprime aussi le volume et ses données.
