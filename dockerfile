FROM node as builder
ARG UPTIME_KUMA_VERSION=1.23.8
ARG LITESTREAM_VERSION=0.3.9

ENV APP_HOME /app
ENV UPTIME_KUMA_VERSION $UPTIME_KUMA_VERSION
ENV LITESTREAM_VERSION $LITESTREAM_VERSION
ENV DATA_DIR "${APP_HOME}/fs/"

RUN env ; mkdir -p "$APP_HOME"
WORKDIR "$APP_HOME"
COPY sources.list /etc/apt/
RUN apt-get update && apt-get -y install iputils-ping wget
RUN rm -rf "$APP_HOME"/uptime-kuma* && wget -qO uptime-kuma-$UPTIME_KUMA_VERSION.tar.gz https://github.com/louislam/uptime-kuma/archive/refs/tags/$UPTIME_KUMA_VERSION.tar.gz && tar xzf uptime-kuma-$UPTIME_KUMA_VERSION.tar.gz
# RUN rm -rf "$APP_HOME"/litestream* && wget -q https://github.com/benbjohnson/litestream/releases/download/v$LITESTREAM_VERSION/litestream-v$LITESTREAM_VERSION-linux-amd64-static.tar.gz && tar xzf litestream-v$LITESTREAM_VERSION-linux-amd64-static.tar.gz

RUN mkdir -p "$APP_HOME/fs"
RUN cd uptime-kuma-$UPTIME_KUMA_VERSION && npm ci --production
COPY /dist uptime-kuma-$UPTIME_KUMA_VERSION/dist
RUN rm -rf "$DATA_DIR" && mkdir -p "$DATA_DIR"
RUN ls -la && mv uptime-kuma-$UPTIME_KUMA_VERSION uptime-kuma

FROM node

COPY sources.list /etc/apt/
RUN apt-get update && apt-get -y install iputils-ping wget

ENV APP_HOME /app
ENV LITESTREAM_BUCKET uptime-kuma
ENV LITESTREAM_PATH uptime-kuma-db

#ADD gen-config.sh "$APP_HOME/gen-config.sh"

ENV DATA_DIR "${APP_HOME}/fs/"
ENV OOM_TIMEOUT "15m"

WORKDIR "$APP_HOME"

COPY sources.list /etc/apt/
RUN apt-get update && apt-get -y install iputils-ping wget
RUN apt-get clean autoclean;apt-get autoremove --yes;rm -rf /var/lib/{apt,dpkg,cache,log}
COPY --from=builder "$APP_HOME" "$APP_HOME"
EXPOSE 9000
CMD /bin/bash -xc 'env ; pwd ; ls -la ; cd uptime-kuma;exec /usr/bin/timeout -k 15s $OOM_TIMEOUT node server/server.js --host=0.0.0.0 --port=9000;'
