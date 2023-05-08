# frozen_string_literal: true

require "socket"

module IPv6
  class Client
    def initialize(ipv6, port)
      @ipv6, @port = ipv6, port

      @socket = TCPSocket.new(ipv6, port)
    end

    def send(data)
      chunks = data.scan(/.{1,6}/)
      received = 0

      chunks.each_with_index do |chunk, index|
        socket.send(chunk, 0)
        socket.send("\n", 0) if index == chunks.size - 1
      end

      while received < data.bytesize
        response = socket.recv(1024)
        puts response
        received += response.bytesize
      end
    end

    def close
      socket.close rescue nil
    end

    private

      attr_reader :ipv6, :port, :socket
  end
end


client = IPv6::Client.new("::1", 8088)

client.send("foo")
client.send("213124sadf")
client.send("sdfswtw4et")
client.send("asdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasdasd")

client.close
