# TP 03 · OpenTofu avancé

Les deux piles se déploient indépendamment. Les exécuter l’une après l’autre car elles partagent les ports locaux 3000 et 8080.

- [DevSecOps](devsecops/) déploie Gitea, Jenkins, SonarQube et PostgreSQL.
- [Supervision](supervision/) relie l’application Node.js à Prometheus, Alloy, Loki et Grafana.

Les deux utilisent Docker en mode conteneurs Linux et le fournisseur Docker 3.6.1 du [B1](../../ateliers/b1-nginx-opentofu/). Dans Ubuntu WSL avec Docker Engine natif, copier les dossiers dans le système de fichiers Linux et démarrer le moteur avec `sudo systemctl start docker`. Sous Docker Desktop, utiliser le contexte Linux et vérifier que le moteur peut lire les fichiers montés par la supervision.

Les accès sont liés à la boucle locale. Les états, plans et fichiers `terraform.tfvars` restent locaux. Chaque pile fournit un exemple de variables et un fichier de verrouillage du fournisseur.
