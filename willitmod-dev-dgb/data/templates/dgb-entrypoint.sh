#!/bin/sh
set -eu

echo "[axedgb] DGB entrypoint starting"

if ! command -v digibyted >/dev/null 2>&1; then
  echo "[axedgb] ERROR: digibyted not found in PATH"
  exit 127
fi

extra=""
if [ -f /data/.reindex-chainstate ]; then
  echo "[axedgb] Reindex requested (chainstate)."
  rm -f /data/.reindex-chainstate || true
  extra="-reindex-chainstate"
fi

dbcache="${DGB_DBCACHE_MB:-}"
if [ -z "$dbcache" ] && [ -f /data/.dbcache_mb ]; then
  raw="$(cat /data/.dbcache_mb 2>/dev/null | tr -d ' \t\r\n' || true)"
  case "$raw" in
    ""|auto|AUTO)
      dbcache=""
      ;;
    *[!0-9]*)
      echo "[axedgb] WARNING: invalid /data/.dbcache_mb value, ignoring"
      dbcache=""
      ;;
    *)
      dbcache="$raw"
      ;;
  esac
fi
if [ -z "$dbcache" ] && [ -r /proc/meminfo ]; then
  mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || true)"
  if [ -n "$mem_kb" ]; then
    mem_mb="$((mem_kb / 1024))"
    if [ "$mem_mb" -lt 12288 ]; then
      # 8GB host -> 4GB dbcache
      dbcache="4096"
    elif [ "$mem_mb" -lt 16384 ]; then
      # 12GB host -> 6GB dbcache
      dbcache="6144"
    else
      # 16GB+ host -> 8GB dbcache
      dbcache="8192"
    fi
  fi
fi

if [ -n "$dbcache" ] && echo "$dbcache" | grep -Eq '^[0-9]+$'; then
  if [ "$dbcache" -lt 4096 ]; then
    echo "[axedgb] WARNING: dbcache=$dbcache too low; clamping to 4096MB minimum"
    dbcache="4096"
  fi
fi

if [ -n "$dbcache" ]; then
  extra="$extra -dbcache=$dbcache"
fi

echo "[axedgb] Exec: digibyted -datadir=/data -printtoconsole $extra"
exec digibyted -datadir=/data -printtoconsole $extra
