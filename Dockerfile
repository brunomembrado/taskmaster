# ---- Build Stage ----
ARG ELIXIR_VERSION=1.17.3
ARG OTP_VERSION=26.2.5.4
ARG DEBIAN_VERSION=bookworm-20260202

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}-slim"

FROM ${BUILDER_IMAGE} AS build

RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

# Install dependencies first (layer caching)
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config before compiling deps
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy application code and compile
COPY lib lib
COPY priv priv

RUN mix compile

# Build the release
COPY config/runtime.exs config/
RUN mix release

# ---- Runtime Stage ----
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

ENV MIX_ENV="prod"
ENV PHX_SERVER="true"

# Copy the release from the build stage
COPY --from=build --chown=nobody:root /app/_build/${MIX_ENV}/rel/taskmaster ./

USER nobody

EXPOSE 4000

CMD ["bin/taskmaster", "start"]
