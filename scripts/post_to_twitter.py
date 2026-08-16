#!/usr/bin/env python3
"""Publica un tuit firmando la petición con OAuth 1.0a.

La API de X (antes Twitter) no acepta un simple token Bearer para
publicar en nombre de un usuario: hay que firmar cada petición con
HMAC-SHA1 (OAuth 1.0a "user context"). Esto lo hace con la librería
estándar de Python, sin dependencias externas que instalar en la
Action.

Uso:
    TWITTER_API_KEY=... TWITTER_API_SECRET=... \
    TWITTER_ACCESS_TOKEN=... TWITTER_ACCESS_TOKEN_SECRET=... \
    python3 scripts/post_to_twitter.py "<título>" "<resumen>" "<url>"

Las cuatro credenciales se sacan del portal de desarrolladores de X
(developer.x.com): una app con permisos "Read and Write", clave y
secreto de la app (API Key/Secret) y, generados DESPUÉS de poner esos
permisos, el access token y su secreto de usuario. A diferencia de
LinkedIn, no caducan solos (solo si se revocan a mano).
"""
import base64
import hashlib
import hmac
import json
import os
import random
import string
import sys
import time
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

TWEETS_URL = os.environ.get("TWITTER_TWEETS_URL", "https://api.twitter.com/2/tweets")
MAX_LEN = 280
# X envuelve cualquier URL con t.co a un tamaño fijo, cuente lo que cuente
# la URL real. Ese tamaño ha rondado los 23 caracteres desde hace años.
TCO_LEN = 23


def percent_encode(value):
    return quote(str(value), safe="")


def oauth_header(method, url, consumer_key, consumer_secret, token, token_secret):
    oauth_params = {
        "oauth_consumer_key": consumer_key,
        "oauth_nonce": "".join(random.choices(string.ascii_letters + string.digits, k=32)),
        "oauth_signature_method": "HMAC-SHA1",
        "oauth_timestamp": str(int(time.time())),
        "oauth_token": token,
        "oauth_version": "1.0",
    }
    # Con cuerpo JSON (no x-www-form-urlencoded), la firma de OAuth 1.0a
    # solo incluye los parámetros oauth_*, no el cuerpo de la petición.
    param_string = "&".join(
        f"{percent_encode(k)}={percent_encode(v)}" for k, v in sorted(oauth_params.items())
    )
    base_string = "&".join([method.upper(), percent_encode(url), percent_encode(param_string)])
    signing_key = f"{percent_encode(consumer_secret)}&{percent_encode(token_secret)}"
    signature = base64.b64encode(
        hmac.new(signing_key.encode(), base_string.encode(), hashlib.sha1).digest()
    ).decode()
    oauth_params["oauth_signature"] = signature
    return "OAuth " + ", ".join(
        f'{percent_encode(k)}="{percent_encode(v)}"' for k, v in sorted(oauth_params.items())
    )


def build_tweet_text(title, excerpt, url):
    intro = title
    if excerpt:
        intro = f"{title} — {excerpt}"
    budget = MAX_LEN - TCO_LEN - 2  # 2 = saltos de línea antes de la url
    if len(intro) > budget:
        intro = intro[: budget - 1].rstrip() + "…"
    return f"{intro}\n\n{url}"


def main():
    if len(sys.argv) < 4:
        print("Uso: post_to_twitter.py <título> <resumen> <url>", file=sys.stderr)
        sys.exit(2)
    title, excerpt, url = sys.argv[1], sys.argv[2], sys.argv[3]

    consumer_key = os.environ["TWITTER_API_KEY"]
    consumer_secret = os.environ["TWITTER_API_SECRET"]
    token = os.environ["TWITTER_ACCESS_TOKEN"]
    token_secret = os.environ["TWITTER_ACCESS_TOKEN_SECRET"]

    text = build_tweet_text(title, excerpt, url)
    header = oauth_header("POST", TWEETS_URL, consumer_key, consumer_secret, token, token_secret)
    body = json.dumps({"text": text}).encode()

    req = Request(
        TWEETS_URL,
        data=body,
        method="POST",
        headers={"Authorization": header, "Content-Type": "application/json"},
    )
    try:
        with urlopen(req) as resp:
            print(resp.read().decode())
    except HTTPError as e:
        print(f"Error {e.code} publicando en X: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
