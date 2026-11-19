#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

version=${1:?Usage: bash pipeline.sh VERSION}
mode=${2:-build}
[[ "$version" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}$ ]]
image="websolutions-api:$version"

if [[ "$mode" == build ]]; then
  printf '\n[1/5] Tests applicatifs\n'
  sudo docker run --rm --mount "type=bind,source=$PWD/app,target=/app,readonly" \
    --workdir /app node:24-alpine node --test server.test.js

  printf '\n[2/5] Construction %s\n' "$image"
  if sudo docker image inspect "$image" >/dev/null 2>&1; then
    echo "Cette version existe déjà. Choisir une nouvelle version." >&2
    exit 1
  fi
  sudo docker build --build-arg "APP_VERSION=$version" -t "$image" app
elif [[ "$mode" == rollback ]]; then
  printf '\n[1–2/5] Réutilisation de la version %s\n' "$version"
else
  echo 'Mode attendu : build ou rollback.' >&2
  exit 1
fi

TF_VAR_api_image=$(sudo docker image inspect --format '{{.Id}}' "$image")
export TF_VAR_api_image
printf '\n[3/5] Configuration Ansible\n'
ansible-playbook -i config/inventory.ini config/site.yml

printf '\n[4/5] Déploiement OpenTofu de %s (%s)\n' "$image" "$TF_VAR_api_image"
plan_dir=$(mktemp -d)
trap 'rm -f "$plan_dir/infra.tfplan"; rmdir "$plan_dir"' EXIT
umask 077
sudo tofu -chdir=infra init -input=false
sudo tofu -chdir=infra fmt -check
sudo tofu -chdir=infra validate
sudo --preserve-env=TF_VAR_api_image tofu -chdir=infra plan -input=false -out="$plan_dir/infra.tfplan"
sudo tofu -chdir=infra apply -input=false "$plan_dir/infra.tfplan"

printf '\n[5/5] Contrôle HTTP via Nginx\n'
url=$(sudo tofu -chdir=infra output -raw health_url)
for attempt in {1..15}; do
  if body=$(curl --silent --fail --max-time 4 "$url"); then
    result=$(python3 -c 'import json, sys; d = json.load(sys.stdin); assert d == {"status": "ok", "database": "ok", "version": sys.argv[1]}; print(json.dumps(d))' "$version" <<< "$body")
    printf 'HTTP 200 %s %s\n' "$url" "$result"
    exit 0
  fi
  sleep 2
done
echo 'Le contrôle de santé a échoué.' >&2
exit 1
