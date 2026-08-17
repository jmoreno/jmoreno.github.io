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
# - Cualquier red en sharing (twitter, instagram, o la que sea) + secret
#   SOCIAL_WEBHOOK_URL configurado -> envía un POST con un JSON
#   {title, url, excerpt, platforms} a esa URL. Ahí puedes enganchar
#   IFTTT, Zapier, Make o Buffer, y decidir en esa automatización qué
#   hacer según el contenido de "platforms" (p. ej. publicar en X solo
#   si "twitter" está en la lista). X/Twitter no tiene integración
#   directa aquí a propósito: su API cobra por publicación de apps de
#   terceros, así que esta vía (webhook) es la que no tiene coste.
#
# Sin "sharing" en el front matter, la entrada no se anuncia en ningún
# sitio (aunque los secrets estén configurados). Sin secrets configurados,
# el script tampoco falla: simplemente no hace nada.
set -euo pipefail

SITE_URL="https://www.saltodemata.es"
# LinkedIn ha empezado a exigir esta cabecera incluso en endpoints que
# antes no la pedían (p. ej. /v2/userinfo empezó a devolver 403 "sin
# permisos" sin ella, aunque el token tuviera el scope correcto). Se
# versiona por mes (AAAAMM) y solo admite, a grandes rasgos, la ventana
# de los últimos ~12 meses -- hay que ir subiendo este valor de vez en
# cuando. Se puede sobreescribir con la variable de entorno del mismo
# nombre sin tocar el script.
LINKEDIN_API_VERSION="${LINKEDIN_API_VERSION:-202606}"

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

# clean_slug <cadena> -> igual que el slug que calcula Jekyll para :title
# en el permalink: colapsa guiones repetidos y recorta los de los bordes.
# Hace falta porque el nombre de archivo no siempre viene limpio (p. ej.
# un título con un espacio al final se convierte en un guión de más al
# final del nombre de archivo).
clean_slug() {
  python3 -c 'import re, sys; s = re.sub(r"-{2,}", "-", sys.argv[1]).strip("-"); print(s)' "$1"
}

# post_url <file> -> URL pública de la entrada, según la colección
post_url() {
  local file="$1" base name
  base=$(basename "$file" .md)
  case "$file" in
    _posts/*)
      name="${base#*-*-*-}" # quita el prefijo YYYY-MM-DD-
      echo "${SITE_URL}/blog/$(clean_slug "$name")/"
      ;;
    _recetas/*) echo "${SITE_URL}/recetas/$(clean_slug "$base")/" ;;
    _libros/*)  echo "${SITE_URL}/libros/$(clean_slug "$base")/" ;;
    _snippets/*) echo "${SITE_URL}/snippets/$(clean_slug "$base")/" ;;
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
    # /rest/posts (la Posts API "nueva") suele exigir que LinkedIn apruebe
    # aparte el acceso a la Community Management API, algo que una app
    # personal no consigue por autoservicio. Por eso usamos /v2/ugcPosts,
    # que sí está incluido en el producto autoservicio "Share on LinkedIn".
    curl -sS -i -X POST "https://api.linkedin.com/v2/ugcPosts" \
      -H "Authorization: Bearer ${LINKEDIN_ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -H "X-Restli-Protocol-Version: 2.0.0" \
      -H "LinkedIn-Version: ${LINKEDIN_API_VERSION}" \
      -d "$(python3 -c '
import json, sys
author, text, url = sys.argv[1:4]
body = {
    "author": author,
    "lifecycleState": "PUBLISHED",
    "specificContent": {
        "com.linkedin.ugc.ShareContent": {
            "shareCommentary": {"text": text},
            "shareMediaCategory": "ARTICLE",
            "media": [{"status": "READY", "originalUrl": url}],
        }
    },
    "visibility": {"com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"},
}
print(json.dumps(body))
' "$LINKEDIN_AUTHOR_URN" "$text" "$url")"
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
