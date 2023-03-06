ARG ELIXIR_VERSION=1.14.2
ARG OTP_VERSION=25.1
ARG LINUX_VERSION=3.17.0

ARG IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${LINUX_VERSION}"

FROM ${IMAGE}
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV="prod"
COPY . ./

ENV PORT 80
ENV ERL_AFLAGS "-sname master"
ENV DEFAULT_ARGS "localhost 3000 /"
CMD ["/bin/sh", "-c", "./client.exs ${ARGS:-${DEFAULT_ARGS}}"]