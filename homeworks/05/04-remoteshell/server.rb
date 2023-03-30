require "socket"
require "open3"
require "pry"
require "timeout"

server = TCPServer.new 3000

CRLF = "\r\n"
END_TOKEN = "__EOF"

%w[INT TERM].each do |signal|
  Signal.trap(signal) do
    exit
  end
end

loop do
  client = server.accept

  loop do
    comm = client.gets.tap do |s|
      s.slice!(CRLF) if s
    end

    next if !comm || comm.strip.size == 0

    puts "Received command: #{comm}"
    stdout, stderr, status = Timeout::timeout(5) { Open3.capture3(comm) } # forbid long-running commands

    client.puts("EXITCODE:")
    client.puts(status.to_s)
    client.puts("OUTPUT:")
    client.puts(stdout)
    client.puts(END_TOKEN)
  end
rescue TimeoutError
  next
rescue StandardError => e
  puts "An error occured: #{e}"
  next
end
