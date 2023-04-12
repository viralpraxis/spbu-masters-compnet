# frozen_string_literal: true

require "socket"
require "timeout"
require "time"

class Integer
  def seconds; self; end
  alias second seconds
end

module UDP
  class Client
    def initialize(host:, port:, server_host:, server_port:, pings_count: 10, timeout: 1.second)
      @socket = UDPSocket.new.tap do |udp_socket|
        udp_socket.bind(host, port)
      end
      @server_host = server_host
      @server_port = server_port
      @pings_count = pings_count
      @timeout = timeout
    end

    def run
      pings_count.times do |i|
        Timeout.timeout(timeout) do
          socket.send("ping #{i} #{current_timestamp_ms}", 0, server_host, server_port)

          loop do
            message, _ = socket.recvfrom(1024)
            _, index, ts = message.split(" ")
            if index == i.to_s
              puts "Ping #{i} #{(current_timestamp_ms - ts.to_i).to_f}s"
              break
            end
          end
        end
      rescue Timeout::Error
        puts "Request timed out"
      end
    end

    private

      attr_reader \
        :socket,
        :server_host,
        :server_port,
        :pings_count,
        :timeout

      def current_timestamp_ms
        DateTime.now.strftime("%Q").to_i
      end
  end
end

UDP::Client.new(
  host: "127.0.0.1",
  port: 8001,
  server_host: "127.0.0.1",
  server_port: 8000
).run

