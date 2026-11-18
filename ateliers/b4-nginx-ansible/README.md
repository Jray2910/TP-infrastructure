# B4 · Déployer Nginx avec Ansible

Configurer Nginx sur [UbuntuDev](../a2-vm-linux-conteneur-web/) depuis une machine de contrôle Linux ou macOS. Sous Windows, une distribution Ubuntu dans WSL peut servir de poste de contrôle si elle atteint la VM.

## Prérequis

- Sur la VM, OpenSSH Server, Python 3 et un compte SSH avec accès à `sudo`.
- Sur le poste de contrôle, Ansible. Sous Ubuntu, installer le paquet avec `sudo apt update` puis `sudo apt install ansible`.
- Dans `inventory.ini`, adapter l’adresse et le compte à la cible. Le fichier fourni utilise l’adresse du réseau privé [A3](../a3-reseau-vm/) et le compte `lab`.

Vérifier l’empreinte de la clé hôte SSH à partir de la console de la VM avec `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`. Depuis le poste de contrôle, vérifier que SSH et le module de test Ansible fonctionnent. Les commandes supposent que la clé privée est déjà configurée pour SSH sur le poste de contrôle.

```sh
ssh lab@192.168.56.20 hostname
ansible -i inventory.ini targets -m ansible.builtin.ping
```

Si la clé est à un emplacement personnalisé, ajouter `-i chemin/vers/cle` à la commande SSH et `--private-key chemin/vers/cle` aux commandes Ansible.

## Déployer et vérifier

```sh
ansible-playbook -i inventory.ini web.yml --syntax-check
ansible-playbook -i inventory.ini web.yml
ansible-playbook -i inventory.ini web.yml
ansible-playbook -i inventory.ini web.yml --check --diff
curl -fsS http://192.168.56.20/ansible.html
```

Ajouter `-K` si `sudo` demande un mot de passe. La deuxième application, juste après la première, doit afficher `changed=0` avec un cache APT encore valide. La réponse HTTP doit contenir `Configuration geree avec Ansible`.

Ansible se connecte en SSH depuis le poste de contrôle et exécute les tâches du playbook dans l’ordre. Dans [B3](../b3-nginx-puppet/), `puppet apply` s’exécute dans la VM et les relations `require` ordonnent les ressources. Dans les deux cas, la page HTTP et le résultat de la seconde application vérifient l’état attendu.

### Résultats observés

Le poste de contrôle était Ubuntu sous WSL avec `ansible-core 2.16.3`. La cible était `UbuntuDev` sur le réseau privé, et le service Nginx était déjà actif après B3.

| Vérification | Résultat |
| --- | --- |
| SSH et `ansible.builtin.ping` | `ubuntudev`, puis `pong` via Python 3 |
| `ansible-playbook --syntax-check` | Syntaxe valide |
| Première application | `ok=4 changed=1 failed=0`. Seule la page est créée. |
| Deuxième application et `--check --diff` | `ok=4 changed=0 failed=0` pour les deux |
| HTTP depuis WSL et Windows | `200`, corps `Configuration geree avec Ansible` |

## Nettoyer

Retirer `/var/www/html/ansible.html` sur la VM avec `sudo rm /var/www/html/ansible.html` après la vérification. Le service Nginx reste disponible pour les prochains essais.
