FROM debian:bookworm-slim

# DigiByte Core v8.26.1 does not publish an official arm64 Linux tarball upstream.
# For arm64, we vendor a repacked `digibyte-8.26.1-aarch64-linux-gnu.tar.xz` extracted from a known-good build.
ARG TARGETARCH
ARG DGB_RELEASE_TAG="v8.26.1"
ARG DGB_VERSION="8.26.1"
ARG DGB_AMD64_SHA256="6dec9e0a0ddaab5e9e18022e57d6e2acccd73413e46b3d4818967e891fc04fc4"
ARG DGB_ARM64_TAR_XZ_SHA256="84833abb948beeb95470bfcda406f5a4ce3c1ecc21ddce508c95c307e96fdda8"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl tar xz-utils libstdc++6 libgcc-s1 libevent-2.1-7 && \
    rm -rf /var/lib/apt/lists/*

COPY assets/digibyte-8.26.1-aarch64-linux-gnu.tar.xz /tmp/dgb-arm64.tar.xz

RUN set -eu; \
    case "${TARGETARCH:-}" in \
      amd64) asset="digibyte-${DGB_VERSION}-x86_64-linux-gnu.tar.gz"; sha="${DGB_AMD64_SHA256}" ;; \
      arm64) asset=""; sha="${DGB_ARM64_TAR_XZ_SHA256}" ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH:-<unset>}"; exit 1 ;; \
    esac; \
    if [ "${TARGETARCH:-}" = "arm64" ]; then \
      echo "${sha}  /tmp/dgb-arm64.tar.xz" | sha256sum -c -; \
      mkdir -p /opt/digibyte; \
      tar -xJf /tmp/dgb-arm64.tar.xz -C /opt/digibyte --strip-components=1; \
      rm -f /tmp/dgb-arm64.tar.xz; \
      if [ -f /opt/digibyte/lib/libdigibyteconsensus.so.0.0.0 ]; then \
        cp -f /opt/digibyte/lib/libdigibyteconsensus.so.0.0.0 /opt/digibyte/lib/libdigibyteconsensus.so.0 || true; \
        cp -f /opt/digibyte/lib/libdigibyteconsensus.so.0.0.0 /opt/digibyte/lib/libdigibyteconsensus.so || true; \
      fi; \
    else \
      url="https://github.com/DigiByte-Core/digibyte/releases/download/${DGB_RELEASE_TAG}/${asset}"; \
      curl -fsSL -o /tmp/dgb.tar.gz "${url}"; \
      echo "${sha}  /tmp/dgb.tar.gz" | sha256sum -c -; \
      mkdir -p /opt/digibyte; \
      tar -xzf /tmp/dgb.tar.gz -C /opt/digibyte --strip-components=1; \
      rm -f /tmp/dgb.tar.gz; \
    fi; \
    mkdir -p /opt/digibyte; \
    install -m 0755 /opt/digibyte/bin/digibyted /usr/local/bin/digibyted; \
    install -m 0755 /opt/digibyte/bin/digibyte-cli /usr/local/bin/digibyte-cli; \
    install -m 0755 /opt/digibyte/bin/digibyte-tx /usr/local/bin/digibyte-tx; \
    install -m 0755 /opt/digibyte/bin/digibyte-util /usr/local/bin/digibyte-util; \
    if [ -f /opt/digibyte/bin/digibyte-wallet ]; then \
      install -m 0755 /opt/digibyte/bin/digibyte-wallet /usr/local/bin/digibyte-wallet; \
    fi

ENV LD_LIBRARY_PATH="/opt/digibyte/lib"

RUN groupadd -g 1000 umbrel 2>/dev/null || true && \
    useradd -m -u 1000 -g 1000 umbrel 2>/dev/null || true && \
    mkdir -p /data && chown -R 1000:1000 /data

USER 1000:1000

EXPOSE 12024 14022

CMD ["digibyted", "-datadir=/data", "-printtoconsole"]
