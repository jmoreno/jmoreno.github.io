---
title: Buscar y reemplazar en varios archivos con ripgrep + sed
date: 2026-08-16
lenguaje: bash
description: Un one-liner para sustituir un texto en todos los archivos que lo contengan.
---

Listar los archivos que contienen `TODO_VIEJO` y reemplazarlo por `TODO_NUEVO` en todos ellos, sin tocar el `.git`:

```bash
rg -l 'TODO_VIEJO' | xargs sed -i 's/TODO_VIEJO/TODO_NUEVO/g'
```

- `rg -l` imprime solo los nombres de archivo con coincidencias.
- `sed -i` edita en el sitio (en macOS hace falta `sed -i ''`).

Este es el formato de un snippet: un poco de contexto y el código que no quiero volver a buscar en Google.
