require "socket"
require "base64"

module Mailer
  SMTP_HOST = "localhost"
  SMTP_PORT = 1025

  FROM_ADDRESS = "iaroslav2k@gmail.com"
  FROM_PORT = "Yaroslav K"

  module_function

  def invoke(to:, filepath:)
    file = File.basename(filepath)
    data = Base64.encode64(File.open(filepath).read)

    socket = TCPSocket.new(SMTP_HOST, SMTP_PORT)

    # intentionally ingore responses, assume happy path
    # internally has ASCII encoding
    socket.puts("EHLO localhost")
    socket.puts("MAIL FROM: <#{FROM_ADDRESS}>")
    socket.puts("RCPT TO: <#{to}>")
    socket.puts("DATA")
    socket.puts("From: Some User <#{FROM_ADDRESS}>")
    socket.puts("Subject: Test Email")
    socket.puts("Content-Type: multipart/mixed; boundary=\"my-boundary\"")
    socket.puts
    socket.puts("--my-boundary")
    socket.puts("Content-Type: text/plain; charset=\"US-ASCII\"")
    socket.puts("Content-Transfer-Encoding: 7bit")
    socket.puts("Content-Disposition: inline")
    socket.puts("Test")
    socket.puts("")
    socket.puts("TestBody")
    socket.puts("")
    socket.puts("--my-boundary")
    socket.puts("Content-Type: application;")
    socket.puts("Content-Transfer-Encoding: base64")
    socket.puts("Content-Disposition: attachment; filename=\"#{file}\"")
    socket.puts()
    socket.puts("#{data}")
    socket.puts()
    socket.puts("--my-boundary")
    socket.puts(".")
    socket.close
  end
end


Mailer.invoke(
  to: ARGV[0] || raise(ArgumentError, "Missing to"),
  filepath: ARGV[1] || raise(ArgumentError, "Missing filepath")
)

puts :OK
