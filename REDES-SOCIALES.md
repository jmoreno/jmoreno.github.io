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
2. En la pestaña **Products** de la app, añade **los dos** productos
   (los dos son autoservicio, sin revisión manual):
   - **"Share on LinkedIn"** (da el scope `w_member_social`, para
     publicar).
   - **"Sign In with LinkedIn using OpenID Connect"** (da los scopes
     `openid`/`profile`, necesarios para saber quién eres — sin este
     producto añadido a *esta* app en concreto, ni siquiera aparecen
     como opción al generar el token).
3. Genera un access token marcando los tres scopes (`openid`, `profile`,
   `w_member_social`) — la forma más simple es la herramienta **Token
   Generator**, en "Docs and Tools" del portal de desarrolladores:
   eliges tu app y los scopes, sin tener que montar tú tampoco el flujo
   OAuth con un *redirect URI* propio. Dura unos 60 días — tendrás que
   regenerarlo periódicamente.
   - Si tienes dudas de qué scopes tiene realmente un token ya
     generado, la herramienta **Token Inspector** (mismo menú) te los
     lista pegando el token.
4. Con ese token, consigue tu *author URN*. Hace falta la cabecera
   `LinkedIn-Version` incluso aquí (si no, da 403 aunque el token tenga
   los scopes correctos):

   ```bash
   curl https://api.linkedin.com/v2/userinfo \
     -H "Authorization: Bearer TU_ACCESS_TOKEN" \
     -H "LinkedIn-Version: 202606"
   ```

   El campo que necesitas de la respuesta es `sub` (una cadena corta
   tipo `98f5Fdovbj`, no un número). Tu *author URN* es
   `urn:li:person:` seguido de ese valor, sin espacios ni comillas de
   más: `urn:li:person:98f5Fdovbj`.
5. Añade dos secrets al repositorio:
   - `LINKEDIN_ACCESS_TOKEN` — el token del paso 3 (vale para lo dos:
     consultar el perfil y publicar).
   - `LINKEDIN_AUTHOR_URN` — el URN del paso 4.

A partir de ahí, cualquier entrada con `linkedin` en su `sharing` se
publica sola en tu perfil, con el título, el resumen y el enlace.

> El script usa el endpoint **`/v2/ugcPosts`** (el que trae de serie el
> producto autoservicio "Share on LinkedIn"), no el más nuevo
> `/rest/posts` — ese exige además el producto "Community Management
> API", que LinkedIn concede tras revisión manual, no por autoservicio.
> Igual que `/v2/userinfo`, lleva la cabecera `LinkedIn-Version`
> (variable `LINKEDIN_API_VERSION` al principio de
> `scripts/social_share.sh`, sube ese número de vez en cuando).
>
> Si `/v2/ugcPosts` rechaza la llamada con un 422 del tipo *"/author ::
> no coincide con urn:li:member/urn:li:company"*, revisa primero el
> **valor exacto** de `LINKEDIN_AUTHOR_URN`: tiene que ser literalmente
> `urn:li:person:` seguido del `sub`, sin espacios ni comillas de más
> — es el error que da si ese valor está mal formado.

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
