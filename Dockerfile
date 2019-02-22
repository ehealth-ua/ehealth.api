FROM elixir:1.8.1-alpine as builder

ARG APP_NAME

ADD . /app

WORKDIR /app

ENV MIX_ENV=prod

RUN apk add git build-base
RUN mix do \
      local.hex --force, \
      local.rebar --force, \
      deps.get, \
      deps.compile, \
      release --name=${APP_NAME}

RUN git log --pretty=format:"%H %cd %s" > commits.txt

FROM alpine:3.9

ARG APP_NAME

RUN apk add --no-cache \
      ncurses-libs \
      zlib \
      ca-certificates \
      openssl \
      bash

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/${APP_NAME}/releases/0.1.0/${APP_NAME}.tar.gz /app
COPY --from=builder /app/commits.txt /app

RUN tar -xzf ${APP_NAME}.tar.gz; rm ${APP_NAME}.tar.gz

ENV REPLACE_OS_VARS=true \
      APP=${APP_NAME}

CMD ./bin/${APP} foreground
