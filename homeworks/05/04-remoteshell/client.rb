require "socket"
require "pry"

END_TOKEN = "__EOF"

socket = TCPSocket.new("localhost", 3000)

while true do
  $stdin&.readline&.then do |string|
    socket.puts(string)

    result = []
    while true do
      item = socket.gets
      break if item.include? END_TOKEN

      result << item
    end

    result&.each do |item|
      puts item.strip
    end

    print "\n"
  end
end
