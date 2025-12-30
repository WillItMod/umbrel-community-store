#!/bin/sh
set -eu

apk add --no-cache envsubst curl >/dev/null

mkdir -p /data/node /data/pool/config /data/pool/www/pool /data/ui/static

if [ -n "${APP_VERSION:-}" ] && [ -n "${UI_SOURCE_BASE:-}" ]; then
  current="$(cat /data/ui/VERSION 2>/dev/null || true)"
  if [ "$current" != "$APP_VERSION" ]; then
    echo "[axebch] Updating UI to $APP_VERSION"
    tmp="$(mktemp -d 2>/dev/null || echo /tmp/axebch-ui)"
    mkdir -p "$tmp/ui/static"
    ok=1
    set +e
    curl -fsSL "${UI_SOURCE_BASE}/data/ui/app.py" -o "$tmp/ui/app.py" || ok=0
    curl -fsSL "${UI_SOURCE_BASE}/data/ui/static/index.html" -o "$tmp/ui/static/index.html" || ok=0
    curl -fsSL "${UI_SOURCE_BASE}/data/ui/static/app.js" -o "$tmp/ui/static/app.js" || ok=0
    curl -fsSL "${UI_SOURCE_BASE}/data/ui/static/app.css" -o "$tmp/ui/static/app.css" || ok=0
    set -e
    if [ "$ok" -eq 1 ]; then
      mkdir -p /data/ui/static
      cp -f "$tmp/ui/app.py" /data/ui/app.py
      cp -f "$tmp/ui/static/index.html" /data/ui/static/index.html
      cp -f "$tmp/ui/static/app.js" /data/ui/static/app.js
      cp -f "$tmp/ui/static/app.css" /data/ui/static/app.css
      printf "%s\n" "$APP_VERSION" > /data/ui/VERSION
      chown -R 1000:1000 /data/ui
    else
      echo "[axebch] WARNING: UI download failed; keeping existing UI"
    fi
    rm -rf "$tmp" >/dev/null 2>&1 || true
  fi
fi

if [ ! -f /data/node/bitcoin.conf ]; then
  envsubst < /data/templates/bitcoin.conf.template > /data/node/bitcoin.conf
  chown -R 1000:1000 /data/node
fi

if [ ! -f /data/pool/config/ckpool.conf ]; then
  envsubst < /data/templates/ckpool.conf.template > /data/pool/config/ckpool.conf
  chown -R 1000:1000 /data/pool
else
  if ! grep -q '"btcaddress"' /data/pool/config/ckpool.conf; then
    mv /data/pool/config/ckpool.conf "/data/pool/config/ckpool.conf.bak.$(date +%s 2>/dev/null || echo 0)" || true
    envsubst < /data/templates/ckpool.conf.template > /data/pool/config/ckpool.conf
    chown -R 1000:1000 /data/pool
  fi
fi
