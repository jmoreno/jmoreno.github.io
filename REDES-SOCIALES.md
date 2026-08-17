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
- `sharing: [linkedin]` → solo LinkedIn, publicación directa.
- Cualquier otro valor (`twitter`, `instagram`, o el que sea) → va al
  webhook genérico (ver más abajo). No hay publicación directa a X:
  ver el porqué en la siguiente sección.
- Se pueden combinar: `sharing: [linkedin, twitter, instagram]`.

El campo tiene que ir en formato de lista entre corchetes; es el único
formato que entiende `scripts/social_share.sh`.

Sin configurar ningún secret, la Action no falla: aunque una entrada
lleve `sharing`, simplemente no publica en ningún sitio. Actívala
configurando los que te interesen en **Settings → Secrets and
variables → Actions** del repositorio.

## Por qué X/Twitter no tiene publicación directa

Lo probamos (firma OAuth 1.0a incluida), pero la API de X factura por
publicación a las apps de terceros — el error real fue
`"detail":"credits depleted","status":402` (*Payment Required*), no un
fallo de configuración. Como no tiene sentido pagar por publicar en X
un blog personal, X queda fuera de la publicación directa a propósito
y se cubre con el webhook genérico (siguiente sección), que no tiene
ese coste porque no habla con la API de X directamente: se lo delegas
a una automatización externa (Zapier, IFTTT...) que ya tenga su propia
conexión con X.

## LinkedIn (publicación directa)

1. Crea una app en <https://www.linkedin.com/developers/apps>.
2. Solicita el producto **"Share on LinkedIn"** (da acceso al scope
   `w_member_social`).
3. Genera un access token (OAuth 2.0, flujo de 3 patas) con ese scope.
   Dura unos 60 días — tendrás que regenerarlo periódicamente.
4. Consigue tu *author URN*: `urn:li:person:TU_ID` (se obtiene con una
   llamada a `GET /v2/userinfo` usando el mismo token; el campo que
   necesitas es `sub`).
5. Añade dos secrets al repositorio:
   - `LINKEDIN_ACCESS_TOKEN`
   - `LINKEDIN_AUTHOR_URN`

A partir de ahí, cualquier entrada con `linkedin` en su `sharing` se
publica sola en tu perfil, con el título, el resumen y el enlace.

> El script usa el endpoint **`/v2/ugcPosts`** (el que trae de serie el
> producto autoservicio "Share on LinkedIn"), no el más nuevo
> `/rest/posts` — ese exige además el producto "Community Management
> API", que LinkedIn concede tras revisión manual, no por autoservicio.
>
> Si `/v2/ugcPosts` rechaza la llamada con un 422 del tipo *"/author ::
> no coincide con urn:li:member/urn:li:company"*, revisa primero el
> **valor exacto** de `LINKEDIN_AUTHOR_URN`: tiene que ser literalmente
> `urn:li:person:` seguido del `sub` que devuelve `/v2/userinfo`, sin
> espacios ni comillas de más.

## Webhook genérico (X/Twitter, Instagram, o cualquier otra red)

Tanto X/Twitter como Instagram exigen, para publicar de verdad desde
tu propia app, cosas que no compensan para un blog personal (X cobra
por publicación de terceros; Instagram exige cuenta de empresa e
imagen obligatoria). La forma simple es delegarlo en una automatización
sin código que ya tenga sus propias conexiones con esas redes:

1. Crea un *applet*/*zap*/escenario en **IFTTT**, **Zapier**, **Make** o
   **Buffer** con un disparador de tipo *Webhook* (en IFTTT es el
   servicio "Webhooks", evento a tu elección, p. ej. `nuevo_post`).
2. Copia la URL del webhook que te den.
3. Añade el secret `SOCIAL_WEBHOOK_URL` al repositorio con esa URL.
4. En la acción del applet (publicar en X, Instagram, Buffer, etc.),
   usa los campos `title`, `url` y `excerpt` que llegan en el JSON —
   por ejemplo como texto del post, y sube tú la imagen si hace falta.

El webhook se dispara para cualquier entrada que tenga **algo** en
`sharing` (no hace falta que sea literalmente `twitter`: puede ser
`instagram`, o cualquier otro nombre que te invente). El JSON incluye
además un campo `platforms` con la lista completa, por si quieres
filtrar en el propio applet según a qué red va dirigido:

```json
{
  "title": "Un post que quiero anunciar",
  "url": "https://www.saltodemata.es/blog/un-post/",
  "excerpt": "...",
  "platforms": ["twitter", "instagram"]
}
```

Por ejemplo, en IFTTT puedes añadir un filtro que compruebe si
`platforms` contiene `"twitter"` antes de publicar ahí, y así usar el
mismo webhook para varias redes sin que se crucen.
