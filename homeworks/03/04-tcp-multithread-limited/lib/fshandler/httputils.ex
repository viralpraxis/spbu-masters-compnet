defmodule HttpUtils do
  @crlf "\r\n"

  @spec build_http_response(nil | maybe_improper_list | map) :: <<_::64, _::_*8>>
  def build_http_response(data) do
    """
    HTTP/1.1 #{data[:status]}#{@crlf}\
    Server: GWS =)#{@crlf}\
    Content-Type: #{data[:content_type] || "application/octet-stream"}#{@crlf}\
    Content-Length: #{data[:bytesize]}#{@crlf}\
    #{@crlf}\
    #{data[:body]}\
    """
  end
end
