FROM elixir:1.7.4-alpine as builder

ARG APP_NAME

ADD . /app

WORKDIR /app

ENV MIX_ENV=prod

RUN apk add git
RUN mix do \
      local.hex --force, \
      local.rebar --force, \
      deps.get, \
      deps.compile, \
      release --name="${APP_NAME}"

FROM alpine:3.8

ARG APP_NAME

RUN apk add --no-cache \
      ncurses-libs \
      zlib \
      ca-certificates \
      openssl \
      bash

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/${APP_NAME}/releases/0.1.0/${APP_NAME}.tar.gz /app

RUN tar -xzf ${APP_NAME}.tar.gz; rm ${APP_NAME}.tar.gz

ENV REPLACE_OS_VARS=true \
      APP=${APP_NAME}

CMD ./bin/${APP} foreground
