defmodule Fshandler.Application do
  use Application

  require Logger
  require Server
  require Handler

  @port_default "3000"

  @spec start(any, any) :: no_return
  def start(_type, _args) do
    Logger.info("Application started at TCP/#{port()}")
    accept()
  end

  defp accept do
    {:ok, socket} = :gen_tcp.listen(port(), [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    case Server.serve(socket) do
      :ok -> serve(socket)
      :closed -> nil
    end
  end

  defp port() do
    (System.get_env("PORT") || @port_default) |> String.to_integer()
  end
end
