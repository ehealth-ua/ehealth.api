FROM elixir:1.6.6-alpine as builder

ARG APP_NAME
ARG APP_VERSION

ADD . /app

WORKDIR /app

ENV MIX_ENV=prod

RUN apk add git
RUN mix do \
      local.hex --force, \
      local.rebar --force, \
      deps.get, \
      deps.compile, \
      release

FROM alpine:3.7

ARG APP_NAME
ARG APP_VERSION

RUN apk add --no-cache \
      ncurses-libs \
      zlib \
      ca-certificates \
      openssl \
      bash

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/${APP_NAME}/releases/${APP_VERSION}/${APP_NAME}.tar.gz /app

RUN tar -xzf ${APP_NAME}.tar.gz; rm ${APP_NAME}.tar.gz

ENV REPLACE_OS_VARS=true \
      APP=${APP_NAME}

CMD ./bin/${APP} foreground
