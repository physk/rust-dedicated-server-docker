FROM debian:12-slim

ARG DEBIAN_FRONTEND=noninteractive

# Package baseline follows LinuxGSM dependency lists (Debian 12 `all` + `steamcmd`)
# plus project runtime tools.
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      bc \
      binutils \
      bsdmainutils \
      bzip2 \
      ca-certificates \
      cpio \
      curl \
      dos2unix \
      file \
      gzip \
      hostname \
      jq \
      lib32gcc-s1 \
      lib32stdc++6 \
      libsdl2-2.0-0:i386 \
      lib32z1 \
      libgdiplus \
      netcat-openbsd \
      passwd \
      pigz \
      procps \
      python3 \
      rsync \
      sudo \
      tar \
      tmux \
      unzip \
      gosu \
      util-linux \
      uuid-runtime \
      wget \
      xz-utils && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash steam

COPY utils/ /utils/
RUN chmod +x /utils/*.sh

COPY docker/convars.map /app/server/convars.map

ENTRYPOINT ["/bin/bash", "/utils/entrypoint.sh"]
