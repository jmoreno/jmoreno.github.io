#!/usr/bin/env bash
# Anuncia en redes sociales las entradas nuevas publicadas en este push.
#
# Qué se comparte y dónde lo decide el front matter de cada entrada con
# el campo "sharing" (una lista, igual que "tags"):
#
#   ---
#   title: Un post que quiero anunciar
#   sharing: [linkedin, instagram]
#   ---
#
# - "linkedin" en sharing + secrets LINKEDIN_ACCESS_TOKEN y
#   LINKEDIN_AUTHOR_URN configurados -> publica directo en LinkedIn.
# - "twitter" en sharing + secrets TWITTER_API_KEY, TWITTER_API_SECRET,
#   TWITTER_ACCESS_TOKEN y TWITTER_ACCESS_TOKEN_SECRET configurados ->
#   publica directo en X/Twitter (scripts/post_to_twitter.py).
# - Cualquier red en sharing (incluida "instagram") + secret
#   SOCIAL_WEBHOOK_URL configurado -> envía un POST con un JSON
#   {title, url, excerpt, platforms} a esa URL. Ahí puedes enganchar
#   IFTTT, Zapier, Make o Buffer, y decidir en esa automatización qué
#   hacer según el contenido de "platforms" (p. ej. publicar en
#   Instagram solo si "instagram" está en la lista).
#
# Sin "sharing" en el front matter, la entrada no se anuncia en ningún
# sitio (aunque los secrets estén configurados). Sin secrets configurados,
# el script tampoco falla: simplemente no hace nada.
set -euo pipefail

SITE_URL="https://www.saltodemata.es"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# front_matter_field <file> <campo>  -> valor del campo (o vacío)
front_matter_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    NR==1 && $0 == "---" { infm=1; next }
    infm && $0 == "---" { exit }
    infm && $0 ~ "^" field ":" {
      sub("^" field ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$file"
}

# sharing_targets <file> -> redes indicadas en "sharing", separadas por
# coma y sin espacios (p. ej. "linkedin,instagram"), o vacío si no hay
# ninguna. Solo entiende el formato "flow": sharing: [linkedin, instagram]
# (así es como se escriben las listas en este blog, ver README.md).
sharing_targets() {
  local file="$1" raw part
  local -a parts out
  raw=$(front_matter_field "$file" "sharing")
  raw="${raw#\[}"
  raw="${raw%\]}"
  out=()
  IFS=',' read -ra parts <<< "$raw"
  for part in "${parts[@]}"; do
    part="$(echo "$part" | xargs)" # recorta espacios sueltos
    [ -n "$part" ] && out+=("$part")
  done
  (IFS=,; echo "${out[*]:-}")
}

# has_sharing_target <file> <red> -> éxito (0) si "sharing" incluye esa red
has_sharing_target() {
  local file="$1" target="$2" list
  list=$(sharing_targets "$file")
  [[ ",${list}," == *",${target},"* ]]
}

# post_url <file> -> URL pública de la entrada, según la colección
post_url() {
  local file="$1" base name
  base=$(basename "$file" .md)
  case "$file" in
    _posts/*)
      name="${base#*-*-*-}" # quita el prefijo YYYY-MM-DD-
      echo "${SITE_URL}/blog/${name}/"
      ;;
    _recetas/*) echo "${SITE_URL}/recetas/${base}/" ;;
    _libros/*)  echo "${SITE_URL}/libros/${base}/" ;;
    _snippets/*) echo "${SITE_URL}/snippets/${base}/" ;;
    *) echo "" ;;
  esac
}

announce() {
  local file="$1"
  local title url excerpt text targets

  title=$(front_matter_field "$file" "title")
  excerpt=$(front_matter_field "$file" "summary")
  [ -z "$excerpt" ] && excerpt=$(front_matter_field "$file" "description")
  url=$(post_url "$file")
  targets=$(sharing_targets "$file")

  [ -z "$title" ] && { echo "Sin título en $file, lo salto"; return; }

  if [ -z "$targets" ]; then
    echo "Nuevo contenido: ${title} (${url}) — sin 'sharing' en el front matter, no se anuncia en ningún sitio"
    return
  fi

  text="${title}"
  [ -n "$excerpt" ] && text="${text} — ${excerpt}"
  text="${text}

${url}"

  echo "Nuevo contenido: ${title} (${url}) — sharing: ${targets}"

  if [ -n "${LINKEDIN_ACCESS_TOKEN:-}" ] && [ -n "${LINKEDIN_AUTHOR_URN:-}" ] && has_sharing_target "$file" "linkedin"; then
    echo "-> Publicando en LinkedIn"
    curl -sS -X POST "https://api.linkedin.com/v2/ugcPosts" \
      -H "Authorization: Bearer ${LINKEDIN_ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -H "X-Restli-Protocol-Version: 2.0.0" \
      -d @- <<JSON
{
  "author": "${LINKEDIN_AUTHOR_URN}",
  "lifecycleState": "PUBLISHED",
  "specificContent": {
    "com.linkedin.ugc.ShareContent": {
      "shareCommentary": { "text": $(printf '%s' "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))') },
      "shareMediaCategory": "ARTICLE",
      "media": [{ "status": "READY", "originalUrl": "${url}" }]
    }
  },
  "visibility": { "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC" }
}
JSON
    echo
  fi

  if [ -n "${TWITTER_API_KEY:-}" ] && [ -n "${TWITTER_API_SECRET:-}" ] \
    && [ -n "${TWITTER_ACCESS_TOKEN:-}" ] && [ -n "${TWITTER_ACCESS_TOKEN_SECRET:-}" ] \
    && has_sharing_target "$file" "twitter"; then
    echo "-> Publicando en X/Twitter"
    python3 "${SCRIPT_DIR}/post_to_twitter.py" "$title" "$excerpt" "$url"
    echo
  fi

  if [ -n "${SOCIAL_WEBHOOK_URL:-}" ]; then
    echo "-> Enviando al webhook genérico (platforms: ${targets})"
    curl -sS -X POST "${SOCIAL_WEBHOOK_URL}" \
      -H "Content-Type: application/json" \
      -d "$(python3 -c '
import json, sys
title, url, excerpt, targets = sys.argv[1:5]
platforms = [t for t in targets.split(",") if t]
print(json.dumps({"title": title, "url": url, "excerpt": excerpt, "platforms": platforms}))
' "$title" "$url" "$excerpt" "$targets")"
    echo
  fi
}

changed_files="${1:-}"
if [ -z "$changed_files" ]; then
  echo "Sin archivos nuevos que anunciar."
  exit 0
fi

while IFS= read -r file; do
  [ -z "$file" ] && continue
  announce "$file"
done <<< "$changed_files"
