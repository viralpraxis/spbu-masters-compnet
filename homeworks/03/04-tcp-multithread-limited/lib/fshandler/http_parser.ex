defmodule HttpParser do
  @spec extract_http_request_path(binary) :: any
  def extract_http_request_path(raw_request) when is_binary(raw_request) do
    String.split(raw_request) |> Enum.at(1)
  end
end
