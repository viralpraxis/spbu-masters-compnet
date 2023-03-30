require "socket"

module Mailer
  SMTP_HOST = "localhost"
  SMTP_PORT = 1025

  FROM_ADDRESS = "iaroslav2k@gmail.com"
  FROM_PORT = "Yaroslav K"

  module_function

  def invoke(to:)
    socket = TCPSocket.new(SMTP_HOST, SMTP_PORT)

    # intentionally ingore responses, assume happy path
    # internally has ASCII encoding
    socket.puts("EHLO localhost")
    socket.puts("MAIL FROM: <#{FROM_ADDRESS}>")
    socket.puts("RCPT TO: <#{to}>")
    socket.puts("DATA")
    socket.puts("From: Some User <#{FROM_ADDRESS}>")
    socket.puts("Subject: Test Email")
    socket.puts("Content-Type: text/plain")
    socket.puts
    socket.puts("Test")
    socket.puts(".")

    socket.close
  end
end


Mailer.invoke(
  to: ARGV[0] || raise(ArgumentError, "Missing to")
)

puts :OK
