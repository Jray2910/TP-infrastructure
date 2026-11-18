# A2 · VM Linux et conteneur web

Créer une VM Ubuntu Server et vérifier l’accès à un conteneur Nginx depuis la VM et le poste hôte.

## Prérequis et paramètres

- VirtualBox et une [ISO Ubuntu Server 24.04 LTS](https://releases.ubuntu.com/noble/) adaptée à l’architecture de l’hôte.
- VM `UbuntuDev`, type Linux / Ubuntu, 2 vCPU, 2 Gio de RAM, disque VDI dynamique de 20 Gio.
- Adaptateur 1 en NAT. Pendant l’installation, activer OpenSSH Server pour les ateliers suivants.

Pour accéder au serveur avec le NAT seul, ajouter une règle TCP dans **Réseau → Adaptateur 1 → Avancé → Redirection de ports**. Saisir `127.0.0.1` comme adresse hôte, `8088` pour les deux ports et laisser l’adresse invitée vide.

Sur le poste utilisé pour cet atelier, une seconde règle NAT redirige `127.0.0.1:2222` vers le port SSH `22` de la VM. L’installation automatique prévoit le compte local `lab` avec accès par clé et `sudo` sans mot de passe dans la VM de TP. La clé privée est conservée dans le profil Windows.

```powershell
ssh -i "$env:USERPROFILE\.ssh\tp-infrastructure-ubuntudev" -p 2222 lab@127.0.0.1
```

## Démarrer Nginx dans la VM

Après l’installation, installer [Docker Engine pour Ubuntu](https://docs.docker.com/engine/install/ubuntu/), puis exécuter dans la VM.

```sh
ip -br addr
ip route
sudo docker run -d --name web-vm -p 8088:80 nginx:1.28-alpine
sudo docker ps
sudo docker exec web-vm nginx -t
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8088/
```

Sur l’hôte Windows, tester la redirection NAT.

```powershell
curl.exe -fsS -o NUL -w '%{http_code}\n' http://127.0.0.1:8088/
```

Les deux requêtes doivent renvoyer `200`. Dans la VM, le port 8088 est publié par Docker vers le port 80 du conteneur. Sur Windows, le port 8088 est redirigé par VirtualBox vers le port 8088 de la VM. Relever l’adresse et la route de la VM ainsi que le code HTTP obtenu dans chaque terminal.

## État de la vérification

L’empreinte SHA-256 de l’ISO Ubuntu Server 24.04.5 correspond à celle publiée par Ubuntu. Après le démarrage sur disque, la connexion SSH au compte `lab` a réussi.

| Vérification | Résultat observé |
| --- | --- |
| `ip -4 -br addr` | `enp0s3` active, adresse NAT `10.0.2.15/24` |
| `ip route` | Route par défaut via `10.0.2.2` sur `enp0s3` |
| `sudo docker exec web-vm nginx -t` | Configuration Nginx valide |
| Requête HTTP dans UbuntuDev | `200` |
| Requête HTTP depuis Windows via la redirection NAT | `200` |

Le conteneur `web-vm` a été retiré après les deux tests HTTP.

## Nettoyer

Dans la VM, exécuter `sudo docker rm -f web-vm`. Conserver `UbuntuDev` pour A3 et A4. Si le test HTTP est repris en A3 après le nettoyage, recréer le conteneur avec la commande ci-dessus.
