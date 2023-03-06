#! /usr/bin/env elixir

defmodule Client.Processor do
  @crlf "\r\n"

  @sleep_default "0"

  def perform_request(host, port, body) do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, :inet, active: false, packet: :line])

    if sleep_before_send_ms() > 0 do
      :timer.sleep(sleep_before_send_ms())
    end

    :ok = :gen_tcp.send(socket, body)

    {:ok, socket}
  end

  def build_http_request(path) when is_binary(path) do
    """
    GET #{path} HTTP/1.1#{@crlf}\
    Accept: application/octet-stream#{@crlf}\
    #{@crlf}\
    """
  end

  defp sleep_before_send_ms() do
    String.to_integer(System.get_env("SLEEP") || @sleep_default)
  end
end

defmodule Client do
  require Logger

  def call(host, port, path) when is_binary(host) and is_binary(port) and is_binary(path) do
    body = Client.Processor.build_http_request(path)
    {:ok, socket} = Client.Processor.perform_request(String.to_charlist(host), String.to_integer(port), body)

    case do_recv(socket) do
      {:ok, data} -> {:ok, data}
      {:error, error} -> Logger.info(Atom.to_string(error))
    end
  end

  defp do_recv(socket, buffer \\ []) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, chunk} -> do_recv(socket, [buffer, chunk]);
      {:error, _} -> {:ok, List.to_string(buffer)}
    end
  end
end

require Logger

args = System.argv()
vals = List.zip([[:host, :port, :path], args]) |> Enum.into(%{})
case vals do
  %{host: host, port: port, path: path} ->
    Logger.info("Provided arguments: " <> host <> " " <> port <> " " <> path)

    case Client.call(host, port, path) do
      {:ok, data} ->IO.puts("Received response:\n" <> data)
      {:error, code} -> IO.puts("An error occured: " <> Atom.to_string(code))
    end
  _ ->
    raise "Invalid arguments were provided"
  end
