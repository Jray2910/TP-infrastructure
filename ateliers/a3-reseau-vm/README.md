# A3 · Connecter UbuntuDev au réseau privé hôte

Réutiliser la [VM UbuntuDev de l’atelier A2](../a2-vm-linux-conteneur-web/). Le premier adaptateur reste en NAT pour la sortie Internet. Le second relie Windows et Ubuntu sur le sous-réseau `192.168.56.0/24`.

## Configurer VirtualBox et Ubuntu

1. Arrêter proprement la VM. Dans **Configuration → Réseau**, garder l’adaptateur 1 en NAT et activer l’adaptateur 2 en mode **Réseau privé hôte**, avec le câble connecté.
2. Sélectionner le réseau privé hôte de VirtualBox. Sur le poste du TP, Windows utilise `192.168.56.1/24` et le DHCP du réseau distribue `192.168.56.101` à `192.168.56.254`. Vérifier que `192.168.56.20` est libre avant de l’attribuer à la VM.
3. Redémarrer la VM. Dans Ubuntu, vérifier le nom de la seconde interface avec `ip -br link`. Adapter le nom `enp0s8` dans [`60-lab.yaml`](60-lab.yaml) si nécessaire. Copier le fichier dans la VM, puis lancer les commandes depuis la console VirtualBox.

```sh
sudo install -m 600 60-lab.yaml /etc/netplan/60-lab.yaml
sudo netplan generate
sudo netplan try
```

Confirmer le changement dans la console. Le fichier configure uniquement la seconde interface et laisse la route par défaut gérée par le DHCP du NAT.

## Vérifier les flux

Dans Ubuntu, vérifier les adresses, la route par défaut et la résolution DNS, puis recréer le conteneur web d’A2.

```sh
ip -4 -br addr
ip route
getent ahostsv4 ubuntu.com
sudo docker run -d --name web-vm -p 8088:80 nginx:1.28-alpine
```

Depuis PowerShell sur Windows, tester la liaison privée. À la première connexion SSH, vérifier que l’empreinte correspond à celle de `/etc/ssh/ssh_host_ed25519_key.pub` dans la VM (`ssh-keygen -lf`), puis l’accepter.

```powershell
ping 192.168.56.20
ssh -i "$env:USERPROFILE\.ssh\tp-infrastructure-ubuntudev" lab@192.168.56.20 hostname
curl.exe -fsS -o NUL -w '%{http_code}\n' http://192.168.56.20:8088/
```

Résultats attendus : l’interface privée porte `192.168.56.20/24`, la route par défaut passe par le NAT, le DNS renvoie une adresse, le ping reçoit des réponses, SSH affiche `ubuntudev` et HTTP renvoie `200`.

### Résultats observés

| Vérification | Résultat |
| --- | --- |
| `ip -4 -br addr` | `enp0s3` en `10.0.2.15/24`, `enp0s8` en `192.168.56.20/24` |
| `ip route` | Route par défaut via `10.0.2.2` sur `enp0s3`, route privée via `enp0s8` |
| `getent ahostsv4 ubuntu.com` et requête HTTPS depuis la VM | Résolution DNS et accès Internet réussis |
| `Test-Connection 192.168.56.20 -Count 2 -Quiet` depuis Windows | `True` |
| SSH sur `192.168.56.20` depuis Windows | `hostname` renvoie `ubuntudev` |
| Requête HTTP sur `192.168.56.20:8088` depuis Windows | `200` |

## Nettoyer

Supprimer le conteneur de test dans Ubuntu avec `sudo docker rm -f web-vm`. Conserver la VM et son réseau privé pour les ateliers suivants. Pour revenir au NAT seul, supprimer `/etc/netplan/60-lab.yaml`, appliquer Netplan, éteindre la VM puis désactiver l’adaptateur 2 dans VirtualBox.
