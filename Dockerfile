FROM gameservermanagers/linuxgsm-docker

# Base image sets USER linuxgsm; switch to root for build-time setup
USER root

# Install system dependencies at build time (not on every container start)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dos2unix \
        rsync \
        sudo \
        vim \
        nano \
        libgdiplus \
        python3-venv \
        lib32z1 \
        passwd && \
    rm -rf /var/lib/apt/lists/*

# Bake venv outside the named volume so it doesn't need runtime recreation
RUN python3 -m venv /opt/linuxgsm-venv && \
    chown -R linuxgsm: /opt/linuxgsm-venv

# Activate for all login shells including `su - linuxgsm`
RUN echo 'source /opt/linuxgsm-venv/bin/activate' > /etc/profile.d/linuxgsm-venv.sh

COPY utils/ /utils/
RUN chmod +x /utils/*.sh

COPY docker/convars.map /app/server/convars.map

ENTRYPOINT ["/bin/bash", "/utils/entrypoint.sh"]
