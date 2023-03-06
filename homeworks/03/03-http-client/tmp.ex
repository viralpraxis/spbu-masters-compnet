# #! /usr/bin/env elixir

# import "client/processor"

# require Logger
# require Client.Processor

# args = System.argv()
# vals = List.zip([[:host, :port, :path], args]) |> Enum.into(%{})
# case vals do
#   %{host: host, port: port, path: path} ->
#     Logger.info("Provided arguments: " <> host <> port <> path)

#     body = Client.Processor.build_http_request(path)
#     Client.Processor.perform_request(host, port, body)
#   _ ->
#     raise "Invalid arguments were provided: " <> vals
# end
