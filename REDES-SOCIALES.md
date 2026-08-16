# Publicar avisos en redes sociales

Cuando haces `git push` de una entrada nueva (en `_posts/`, `_recetas/`,
`_libros/` o `_snippets/`), la Action
[`.github/workflows/social-share.yml`](.github/workflows/social-share.yml)
se dispara sola. No hace nada por publicar el blog en sí (eso ya lo hace
GitHub Pages) — solo se encarga del aviso en redes.

## Elegir dónde se anuncia cada entrada

Cada entrada decide por sí misma dónde se anuncia con el campo
`sharing` en el front matter (una lista, igual que `tags`):

```markdown
---
title: Un post que quiero anunciar
sharing: [linkedin, instagram]
---
```

- Sin `sharing`, la entrada no se anuncia en ningún sitio — es opt-in,
  no pasa nada por defecto.
- `sharing: [linkedin]` → solo LinkedIn.
- `sharing: [instagram]` → solo el webhook genérico (ver más abajo).
- `sharing: [linkedin, instagram]` → los dos.

El campo tiene que ir en formato de lista entre corchetes; es el único
formato que entiende `scripts/social_share.sh`.

Sin configurar ningún secret, la Action no falla: aunque una entrada
lleve `sharing`, simplemente no publica en ningún sitio. Actívala
configurando los que te interesen en **Settings → Secrets and
variables → Actions** del repositorio.

## LinkedIn (publicación directa)

1. Crea una app en <https://www.linkedin.com/developers/apps>.
2. Solicita el producto **"Share on LinkedIn"** (da acceso al scope
   `w_member_social`).
3. Genera un access token (OAuth 2.0, flujo de 3 patas) con ese scope.
   Dura unos 60 días — tendrás que regenerarlo periódicamente.
4. Consigue tu *author URN*: `urn:li:person:TU_ID` (se obtiene con una
   llamada a `GET /v2/userinfo` o `/v2/me` usando el mismo token).
5. Añade dos secrets al repositorio:
   - `LINKEDIN_ACCESS_TOKEN`
   - `LINKEDIN_AUTHOR_URN`

A partir de ahí, cualquier entrada con `linkedin` en su `sharing` se
publica sola en tu perfil con el título, el resumen y el enlace.

> La API de LinkedIn cambia de vez en cuando (el endpoint `ugcPosts` es
> el "clásico"; existe también `/rest/posts`, más nuevo). Si LinkedIn
> deja de aceptar la llamada, hay que ajustar `scripts/social_share.sh`.

## Instagram (y cualquier otra red)

Instagram exige una cuenta de empresa/creador vinculada a Facebook y una
imagen obligatoria en cada publicación — implementarlo directamente no es
"sencillo". La forma simple es delegarlo en una automatización sin código:

1. Crea un *applet*/*zap*/escenario en **IFTTT**, **Zapier**, **Make** o
   **Buffer** con un disparador de tipo *Webhook* (en IFTTT es el
   servicio "Webhooks", evento a tu elección, p. ej. `nuevo_post`).
2. Copia la URL del webhook que te den.
3. Añade el secret `SOCIAL_WEBHOOK_URL` al repositorio con esa URL.
4. En la acción del applet (publicar en Instagram, Buffer, etc.), usa los
   campos `title`, `url` y `excerpt` que llegan en el JSON — por ejemplo
   como texto del pie de foto, y sube tú la imagen o usa una fija.

El webhook se dispara para cualquier entrada que tenga **algo** en
`sharing` (no hace falta que sea literalmente `instagram`: puede ser
`linkedin`, `instagram`, o cualquier otro nombre que te invente). El
JSON incluye además un campo `platforms` con la lista completa, por si
quieres filtrar en el propio applet según a qué red va dirigido:

```json
{
  "title": "Un post que quiero anunciar",
  "url": "https://www.saltodemata.es/blog/un-post/",
  "excerpt": "...",
  "platforms": ["linkedin", "instagram"]
}
```

Por ejemplo, en IFTTT puedes añadir un filtro que compruebe si
`platforms` contiene `"instagram"` antes de publicar ahí, y así usar el
mismo webhook para varias redes sin que se crucen.
