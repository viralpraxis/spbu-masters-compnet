# frozen_string_literal: true

require 'socket'

module IPv6
  class Server
    def initialize(port)
      @server = TCPServer.new "::1", port
    end

    def start
      puts "server: ready to accept\n"

      loop do
        client = server.accept
        process_async(client)
      end
    end

    def close
      server.close
    end

    private

      attr_reader :server

      def process_async(client)
        Thread.new do
          print "Received: "
          while line = client.gets
            print line.tr("\n", "")
            client.puts line.upcase
          end
          print "\n"

          client.close
        end
      end
  end
end


server = IPv6::Server.new(8088)

Signal.trap("INT") do
  server&.close rescue nil
  puts "done"
  exit 0
end

Signal.trap("TERM") do
  server&.close rescue nil
  puts "done"
  exit 0
end

server.start
