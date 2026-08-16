#!/usr/bin/env bash
# Anuncia en redes sociales las entradas nuevas publicadas en este push.
#
# - Si existen los secrets LINKEDIN_ACCESS_TOKEN y LINKEDIN_AUTHOR_URN,
#   Y la entrada tiene el tag "linkedin" en su front matter, publica
#   directamente en LinkedIn con la API de LinkedIn. Sin ese tag, se
#   salta LinkedIn aunque los secrets estén configurados.
# - Si existe el secret SOCIAL_WEBHOOK_URL, envía un POST con un JSON
#   {title, url, excerpt} a esa URL para TODAS las entradas nuevas. Ahí
#   puedes enganchar IFTTT, Zapier, Make o Buffer para que reenvíen el
#   aviso a Instagram (o donde quieras).
#
# Si no hay secrets configurados, el script no falla: simplemente no hace nada.
set -euo pipefail

SITE_URL="https://www.saltodemata.es"
LINKEDIN_TAG="linkedin"

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

# has_tag <file> <tag> -> éxito (0) si el front matter incluye ese tag
#
# Solo entiende tags en formato "flow": tags: [linkedin, otro-tag]
# (así es como se escriben en este blog, ver README.md).
has_tag() {
  local file="$1" tag="$2" raw part
  raw=$(front_matter_field "$file" "tags")
  raw="${raw#\[}"
  raw="${raw%\]}"
  IFS=',' read -ra parts <<< "$raw"
  for part in "${parts[@]}"; do
    part="$(echo "$part" | xargs)" # recorta espacios sueltos
    [ "$part" = "$tag" ] && return 0
  done
  return 1
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
  local title url excerpt text

  title=$(front_matter_field "$file" "title")
  excerpt=$(front_matter_field "$file" "summary")
  [ -z "$excerpt" ] && excerpt=$(front_matter_field "$file" "description")
  url=$(post_url "$file")

  [ -z "$title" ] && { echo "Sin título en $file, lo salto"; return; }

  text="${title}"
  [ -n "$excerpt" ] && text="${text} — ${excerpt}"
  text="${text}

${url}"

  echo "Nuevo contenido: ${title} (${url})"

  if [ -n "${LINKEDIN_ACCESS_TOKEN:-}" ] && [ -n "${LINKEDIN_AUTHOR_URN:-}" ] && has_tag "$file" "$LINKEDIN_TAG"; then
    echo "-> Publicando en LinkedIn (tiene el tag '${LINKEDIN_TAG}')"
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
  elif [ -n "${LINKEDIN_ACCESS_TOKEN:-}" ] && [ -n "${LINKEDIN_AUTHOR_URN:-}" ]; then
    echo "-> Sin tag '${LINKEDIN_TAG}', no se publica en LinkedIn"
  fi

  if [ -n "${SOCIAL_WEBHOOK_URL:-}" ]; then
    echo "-> Enviando al webhook genérico (Instagram/otros vía IFTTT-Zapier-Buffer)"
    curl -sS -X POST "${SOCIAL_WEBHOOK_URL}" \
      -H "Content-Type: application/json" \
      -d "$(python3 -c 'import json,sys; print(json.dumps({"title": sys.argv[1], "url": sys.argv[2], "excerpt": sys.argv[3]}))' "$title" "$url" "$excerpt")"
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
