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
sharing: [linkedin, twitter, instagram]
---
```

- Sin `sharing`, la entrada no se anuncia en ningún sitio — es opt-in,
  no pasa nada por defecto.
- `sharing: [linkedin]` → solo LinkedIn.
- `sharing: [twitter]` → solo X/Twitter.
- `sharing: [instagram]` → solo el webhook genérico (ver más abajo).
- Se pueden combinar: `sharing: [linkedin, twitter, instagram]` → las tres.

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
publica sola en tu perfil, con el título, el resumen y el enlace.

> El script usa el endpoint **`/v2/ugcPosts`** (el que trae de serie el
> producto autoservicio "Share on LinkedIn"), no el más nuevo
> `/rest/posts`. Probamos `/rest/posts` en su momento porque es el que
> recomienda la documentación actual de LinkedIn, pero da un 403 sin
> más detalle en apps personales: ese endpoint exige además el producto
> **"Community Management API"**, que LinkedIn concede tras una
> revisión manual — no es autoservicio como "Share on LinkedIn", así
> que una app personal normal no lo consigue sin más. `/v2/ugcPosts`
> sigue siendo la vía accesible sin pedir permiso a nadie.
>
> Si en algún momento `/v2/ugcPosts` empieza a rechazar la llamada
> (LinkedIn cambia esto de vez en cuando sin avisar demasiado), lo
> primero es comprobar el **valor exacto** de `LINKEDIN_AUTHOR_URN`:
> tiene que ser literalmente `urn:li:person:` seguido del `sub` que
> devuelve `/v2/userinfo`, sin espacios ni comillas de más — un error
> de formato ahí produce justo un 422 con un mensaje de "no coincide
> con urn:li:member/urn:li:company" que puede confundirse con un
> problema del endpoint cuando en realidad es un dato mal copiado.

## X / Twitter (publicación directa)

A diferencia de LinkedIn, la API de X no acepta un simple token: cada
petición se firma con OAuth 1.0a (HMAC-SHA1). Eso ya está resuelto en
[`scripts/post_to_twitter.py`](scripts/post_to_twitter.py), sin
dependencias externas — solo hace falta rellenar cuatro secrets.

1. Crea una cuenta de desarrollador en <https://developer.x.com> (es
   gratis; el nivel "Free" permite publicar tuits, con un límite mensual
   bajo pero de sobra para un blog personal).
2. Crea un *Project* y una *App* dentro de él.
3. En **App settings → User authentication settings**, actívalo con
   permisos **"Read and Write"** (por defecto suele venir en
   "Read only").
4. En la pestaña **"Keys and tokens"**:
   - Copia la **API Key** y el **API Key Secret** (también llamados
     *Consumer Key/Secret*).
   - Genera (o regenera, si ya existían de antes de poner permisos de
     escritura) el **Access Token** y el **Access Token Secret**.
5. Añade los cuatro secrets al repositorio:
   - `TWITTER_API_KEY`
   - `TWITTER_API_SECRET`
   - `TWITTER_ACCESS_TOKEN`
   - `TWITTER_ACCESS_TOKEN_SECRET`

A partir de ahí, cualquier entrada con `twitter` en su `sharing` se
publica sola como tuit (título, resumen y enlace, recortado a 280
caracteres si hace falta). A diferencia del token de LinkedIn, este no
caduca solo con el tiempo — solo si lo revocas a mano o rotas las claves.

> **Error `client-not-enrolled` / "must use keys and tokens from a
> developer App that is attached to a Project"**: significa que la App
> no está dentro de ningún Project, aunque tengas claves generadas. En
> el [portal de desarrolladores](https://developer.x.com), en
> **Projects & Apps**, comprueba que la App aparece colgando de un
> Project (no como "Standalone App" suelta). Si aparece suelta, o el
> Project no tiene ningún plan de acceso asignado (ni siquiera el
> "Free"), muévela dentro de un Project o créalo de cero desde ahí —
> las claves generadas fuera de un Project no sirven aunque parezcan
> válidas.

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
