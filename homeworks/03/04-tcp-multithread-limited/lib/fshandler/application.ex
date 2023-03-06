defmodule Fshandler.Application do
  use Application

  require Logger
  require Server
  require Handler

  @port_default "80"
  @concurrency_default "10"

  @spec start(any, any) :: no_return
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || @port_default)

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
        handle_socket(socket)
      {:error, message} ->
        Logger.error("Error: " <> inspect(message))
    end
  end

  defp handle_socket(socket) do
    concurrency = concurrency()
    s = Stream.repeatedly(fn -> next_client(socket) end)

     Task.Supervisor.async_stream(Fshandler.TaskSupervisor, s, fn (client) -> serve(client) end, max_concurrency: concurrency, timeout: :infinity)
      |> Enum.to_list()
  end

  defp next_client(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        Logger.info("Accepted new client")
        client
      _ -> nil
    end
  end

  defp serve(client) do
    case Server.serve(client) do
      :ok -> serve(client)
      :closed ->
        Logger.info("Done")
        nil
    end
  end

  defp concurrency do
    String.to_integer(System.get_env("CONCURRENCY") || @concurrency_default)
  end
end
