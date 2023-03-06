defmodule Fshandler.Application do
  use Application

  require Logger
  require Server
  require Handler

  @port_default "3000"

  @spec start(any, any) :: no_return
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || @port_default)

    Logger.info Integer.to_string(port)

    children_specification = [
      {Task.Supervisor, name: Fshandler.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> accept(port) end}, restart: :permanent)
    ]

    Supervisor.start_link(children_specification, [strategy: :one_for_one, name: Fshandler.Supervisor])
  end

  def accept(port) do
    case :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        Logger.info "Accepting connections on TCP/#{port}"
        loop_acceptor(socket)
      {:error, message} ->
        Logger.error(message)
    end
  end

  defp loop_acceptor(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        {:ok, pid} = Task.Supervisor.start_child(Fshandler.TaskSupervisor, fn -> serve(client) end)
        :ok = :gen_tcp.controlling_process(client, pid)
        loop_acceptor(socket)
      {error, _} ->
        Logger.info(error)
    end
  end

  defp serve(socket) do
    case Server.serve(socket) do
      :ok -> serve(socket)
      :closed -> nil
    end
  end
end
