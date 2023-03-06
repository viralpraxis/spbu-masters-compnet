ARG ELIXIR_VERSION=1.14.2
ARG OTP_VERSION=25.1
ARG LINUX_VERSION=3.17.0

ARG IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${LINUX_VERSION}"

FROM ${IMAGE}
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV="prod"
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
COPY lib lib
RUN mix compile

ENV PORT 80
ENV ERL_AFLAGS "-sname master"
CMD ["mix", "run", "--no-halt"]