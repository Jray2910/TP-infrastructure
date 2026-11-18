# A4 · Attacher et monter un disque virtuel

Réutiliser la [VM UbuntuDev d’A2](../a2-vm-linux-conteneur-web/). L’atelier ajoute un disque de données et vérifie que le fichier témoin reste lisible après démontage et remontage.

## Attacher et identifier le disque

1. Éteindre UbuntuDev. Dans **Configuration → Stockage** de VirtualBox, ajouter au contrôleur SATA un VDI dynamique de 2 Gio. Sur le poste de TP, le fichier s’appelle `UbuntuDev-a4-data.vdi` et occupe le port SATA 1. Le disque système occupe le port 0.
2. Démarrer la VM et comparer l’inventaire des disques avant et après l’ajout.

```sh
lsblk -e7 -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
ls -l /dev/disk/by-path/
findmnt -n -o SOURCE /
sudo wipefs --no-act /dev/sdb
```

Les commandes de la suite supposent que le nouveau disque est `/dev/sdb`. Adapter les chemins au résultat de `lsblk`. Avant de partitionner, confirmer que c’est le nouveau disque de 2 Gio, sans partition, sans montage ni signature. Le partitionnement et le formatage effacent les données du périphérique choisi.

## Partitionner, formater et vérifier

```sh
sudo fdisk /dev/sdb
```

Dans `fdisk`, saisir `g` pour créer une table GPT puis `n` pour créer une partition. Valider les valeurs par défaut et saisir `w` pour écrire la table. Vérifier avec `lsblk` que la partition est bien `/dev/sdb1`, puis exécuter les commandes suivantes.

```sh
sudo mkfs.ext4 /dev/sdb1
sudo mkdir -p /mnt/lab-data
sudo mount /dev/sdb1 /mnt/lab-data
findmnt /mnt/lab-data
echo 'Disque de test' | sudo tee /mnt/lab-data/temoin.txt
sudo umount /mnt/lab-data
sudo mount /dev/sdb1 /mnt/lab-data
cat /mnt/lab-data/temoin.txt
```

Le fichier doit toujours contenir `Disque de test`. `findmnt` permet de vérifier que le fichier a été écrit sur le disque de données monté.

## Montage permanent avec l’UUID

Relever l’UUID avec `sudo blkid /dev/sdb1`, puis ajouter à `/etc/fstab` une ligne comme celle-ci en remplaçant le marqueur par l’UUID relevé.

```fstab
UUID=UUID_DU_DISQUE /mnt/lab-data ext4 defaults,nofail 0 2
```

Après modification, exécuter `sudo systemctl daemon-reload`, puis démonter avec `sudo umount /mnt/lab-data`. `sudo mount /mnt/lab-data` doit maintenant utiliser l’entrée de `fstab`. Vérifier avec `findmnt /mnt/lab-data` et relire le fichier témoin.

## Résultats observés

| Vérification | Résultat |
| --- | --- |
| `lsblk`, chemin SATA et `wipefs --no-act` | `/dev/sdb` identifié comme le nouveau disque de 2 Gio, sans signature. La racine est montée sur `/dev/sda2`. |
| `fdisk` puis `mkfs.ext4` | Table GPT et partition `/dev/sdb1` formatée en ext4. |
| `findmnt /mnt/lab-data` | `/dev/sdb1` monté en ext4 sur `/mnt/lab-data`. |
| `cat /mnt/lab-data/temoin.txt` après remontage manuel | `Disque de test` |
| `sudo mount /mnt/lab-data` puis lecture du fichier | Le montage via l’UUID dans `fstab` réussit et le fichier contient toujours `Disque de test`. |

## Nettoyer

Pour détacher le disque, retirer d’abord son entrée dans `/etc/fstab` si elle a été ajoutée, puis recharger la configuration avec `sudo systemctl daemon-reload`. Démonter `/mnt/lab-data`, arrêter la VM et retirer le disque du port SATA 1 dans VirtualBox. Conserver le fichier VDI si les données doivent rester disponibles.
