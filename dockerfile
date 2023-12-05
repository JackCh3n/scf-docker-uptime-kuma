ARG BASE_IMAGE=louislam/uptime-kuma:base2
############################################
# ⭐ Main Image
############################################
FROM $BASE_IMAGE AS release
## Install Git
RUN apt update \
    && apt --yes --no-install-recommends install curl \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt --yes --no-install-recommends  install git

#LABEL org.opencontainers.image.source="https://github.com/louislam/uptime-kuma"

ENV UPTIME_KUMA_IS_CONTAINER=1

# Copy app files from build layer
COPY --chown=node:node . /app
WORKDIR /app
RUN npm run setup

USER node
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD extra/healthcheck
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["node", "server/server.js", "--host=0.0.0.0", "--port=9000"]
