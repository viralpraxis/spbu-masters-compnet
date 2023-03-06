defmodule Handler do
  @http_404_response_body "Oops! Requested file was not found\n"
  @http_405_response_body "Method Not Allowed\n"

  @spec handle(%{:path => binary, :verb => any, optional(any) => any}) :: %{
          :body => atom | binary,
          :bytesize => non_neg_integer,
          :status => <<_::48, _::_*8>>,
          optional(:content_type) => <<_::80>>
        }
  def handle(%{verb: verb, path: path}) when is_binary(path) do
    case verb do
      "GET" ->
        {result, data} = File.read(prepare_path(path))

        case result do
          :ok -> http_200(path, data)
          _ -> http_404(path)
        end
      _ -> http_405(path)
    end
  end

  defp http_200(path, data) when is_binary(path) do
    case File.stat path do
      {:ok, %{size: size}} -> %{bytesize: size, body: data, status: "200 OK"}
      {:error, _reason} -> http_404(path)
    end
  end

  defp http_404(path) when is_binary(path) do
    %{
      bytesize: byte_size(@http_404_response_body),
      body: @http_404_response_body,
      status: "404 Not Found",
      content_type: "text/plain"
    }
  end

  defp http_405(path) when is_binary(path) do
    %{
      bytesize: byte_size(@http_405_response_body),
      body: @http_405_response_body,
      status: "405 Method Not Allowed",
      content_type: "text/plain"
    }
  end

  defp prepare_path(path) when is_binary(path) do
    case String.starts_with?(path, "/") do
      :true -> path
      :false -> path |> String.replace_prefix("", "/")
    end
  end
end
