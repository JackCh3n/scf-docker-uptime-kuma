ARG BASE_IMAGE=louislam/uptime-kuma:base2
############################################
# ⭐ Main Image
############################################
FROM $BASE_IMAGE AS release
USER node
WORKDIR /app

LABEL org.opencontainers.image.source="https://github.com/louislam/uptime-kuma"

ENV UPTIME_KUMA_IS_CONTAINER=1
ENV UPTIME_KUMA_PORT=9000
ENV UPTIME_KUMA_HOST=0.0.0.0

# Copy app files from build layer
COPY --chown=node:node --from=build /app /app

EXPOSE 3001
EXPOSE 9000
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD extra/healthcheck
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "server/server.js"]