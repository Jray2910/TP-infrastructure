# B3 · Configurer Nginx avec Puppet

Puppet installe Nginx, crée une page dédiée et maintient le service actif. Le manifeste s’applique directement dans la VM en mode `puppet apply`.

## Prérequis

Réutiliser [UbuntuDev](../a2-vm-linux-conteneur-web/), avec le port `80` libre ou déjà utilisé par le service Nginx de la VM. Copier ce dossier dans UbuntuDev, puis exécuter les commandes depuis sa racine. Le paquet `puppet-agent` provient du dépôt Ubuntu `universe`.

```sh
sudo apt update
sudo apt install puppet-agent
puppet --version
```

## Appliquer et vérifier

```sh
puppet parser validate site.pp modules/web_nginx/manifests/init.pp
sudo puppet apply --modulepath="$PWD/modules" --noop site.pp
sudo puppet apply --modulepath="$PWD/modules" --detailed-exitcodes site.pp
systemctl is-active nginx
curl -fsS http://127.0.0.1/puppet.html
sudo puppet apply --modulepath="$PWD/modules" --detailed-exitcodes site.pp
```

Avec `--detailed-exitcodes`, `2` indique une application réussie avec changements, `0` une application réussie sans changement. La seconde application doit retourner `0`.

## Vérifier la remise en conformité

```sh
printf 'Modification manuelle\n' | sudo tee /var/www/html/puppet.html
curl -fsS http://127.0.0.1/puppet.html
sudo puppet apply --modulepath="$PWD/modules" --detailed-exitcodes site.pp
curl -fsS http://127.0.0.1/puppet.html
```

Avant la correction, la page affiche `Modification manuelle`. Après application, elle doit afficher `Configuration geree avec Puppet`.

### Résultats observés

| Vérification | Résultat sur UbuntuDev |
| --- | --- |
| Version et validation | Puppet `8.4.0`, syntaxe valide |
| Simulation `--noop` | Installation du paquet, création de la page et activation du service prévues |
| Première application | Code `2`, service `active`, page lisible en HTTP |
| Deuxième application | Code `0`, aucun changement |
| Application après modification manuelle | Code `2`, contenu `Configuration geree avec Puppet` restauré |

## Nettoyer

Retirer la page dédiée avec `sudo rm /var/www/html/puppet.html` quand le test est terminé. Le service Nginx peut être réutilisé pour B4.
