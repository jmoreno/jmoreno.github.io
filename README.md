# javimoreno.es / saltodemata.es

Blog personal de Javi Moreno, reconstruido como un **"git blog"**: publicar
es escribir un archivo Markdown y hacer `git push`. GitHub Pages compila el
sitio con Jekyll automáticamente en cada push a la rama por defecto — no
hace falta ningún paso de build manual ni ninguna Action para publicar.

## Cómo escribir una entrada

Cada zona del blog es una carpeta. Crea un archivo `.md` dentro con
cabecera (front matter) y contenido en Markdown, haz commit y `git push`:
en unos minutos está publicado.

### Blog principal — ideas y reflexiones sueltas

```
_posts/2026-08-16-mi-idea-suelta.md
```

```markdown
---
title: Mi idea suelta
summary: Una frase corta que resume el post (opcional, se usa en el índice).
tags: [opcional, otro-tag]
---

Contenido en Markdown.
```

El nombre del archivo **debe** empezar por `AAAA-MM-DD-`; el resto es la
URL (`/blog/mi-idea-suelta/`).

### Recetas

```
_recetas/nombre-de-la-receta.md
```

```markdown
---
title: Nombre de la receta
date: 2026-08-16
tiempo: 30 min
raciones: 4 personas
description: Una frase corta para el índice.
---

## Ingredientes
...
## Receta
...
```

### Libros

```
_libros/titulo-del-libro.md
```

```markdown
---
title: Título del libro
autor: Nombre del autor
date: 2026-08-16      # fecha en la que se hace la ficha
valoracion: 4          # opcional, de 1 a 5
description: Una frase corta para el índice.
---

Comentarios sobre el libro.
```

### Snippets

```
_snippets/nombre-del-snippet.md
```

```markdown
---
title: Nombre del snippet
date: 2026-08-16
lenguaje: bash
description: Qué hace y para qué sirve.
---

```bash
echo "código"
```
```

## Artículos antiguos (versión 1.0)

Los artículos antiguos que están escritos en Markdown se suben igual que
cualquier entrada nueva: se colocan en `_posts/` respetando su fecha
original en el nombre del archivo (`AAAA-MM-DD-titulo.md`) y Jekyll los
integra automáticamente en el blog, en su sitio cronológico.

El contenido ya existente de versiones anteriores (incluida la versión
1.0 ya compilada en `/1.0/`) no se ha tocado ni movido: sigue disponible
tal cual en sus URLs originales y enlazado desde [/anterior/](/anterior/).

## Desarrollo en local

```bash
bundle install
bundle exec jekyll serve
```

Abre `http://localhost:4000`.

## Estructura

```
_config.yml        configuración del sitio, colecciones y navegación
_layouts/           plantillas (una por zona + genéricas)
_includes/           cabecera, pie, y el bloque de compartir en redes
_posts/              blog principal (zona "sin hilo conductor")
_recetas/            colección de recetas
_libros/             colección de fichas de lectura
_snippets/           colección de snippets de código
assets/css/style.css estilos del sitio nuevo
scripts/              scripts usados por las Actions (aviso en redes)
```

Las carpetas `1.0/`, `apuntes/`, `archivo/`, `fichas/` y `permanentes/`
son HTML estático de versiones anteriores del blog: no pasan por Jekyll,
se sirven tal cual para no romper enlaces antiguos.

## Publicar avisos en redes sociales

Ver [REDES-SOCIALES.md](REDES-SOCIALES.md).

## Nota de seguridad

El `Rakefile` que usaba la versión anterior del blog (ya eliminado)
contenía claves de API de Twitter y un token de integración de Medium en
texto plano. Siguen visibles en el historial de git de este repositorio.
Si esas credenciales todavía están activas en algún sitio, conviene
revocarlas/regenerarlas cuanto antes; si ya estaban inactivas, no hay
nada que hacer salvo tenerlo en cuenta.
