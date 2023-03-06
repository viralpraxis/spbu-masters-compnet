defmodule Server do
  require Logger
  require Handler
  require HttpUtils

  def serve(socket) do
    case read(socket) do
      {:ok, status, headers} ->
        {status, headers}
        |> parse
        |> process
        |> respond(socket)
        |> close(socket) # We intentionally close the socket here
      {:closed} ->
        Logger.info("Closed TCP connection")
        :closed
    end
  end

  defp read(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, status} -> {:ok, status, read_headers(socket)}
      {:error, _} -> {:closed}
    end
  end

  defp parse({status, _headers}) do
    [verb, path, _version] = String.split(status)

    Logger.info("Received request: " <> status)

    %{verb: verb, path: path}
  end

  defp process(request) do
    Handler.handle(request)
  end

  defp respond(data, socket) do
    socket |> :gen_tcp.send(HttpUtils.build_http_response(data))
  end

  defp close(_, socket) do
    :gen_tcp.close(socket)
  end

  defp read_headers(socket, headers \\ []) do
    {:ok, data} = :gen_tcp.recv(socket, 0)

    case Regex.run(~r/(\w+): (.*)/, data) do
      [_data, key, value] -> [{key, value}] ++ read_headers(socket, headers)
      _ -> []
    end
  end
end
