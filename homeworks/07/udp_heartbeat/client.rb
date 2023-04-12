# frozen_string_literal: true

require "socket"
require "time"

module UDP
  class Client
    def initialize(host:, port:, server_host:, server_port:, period_s: 0.5)
      @socket = UDPSocket.new.tap do |udp_socket|
        udp_socket.bind(host, port)
      end
      @server_host = server_host
      @server_port = server_port
      @period_s = period_s
    end

    def run
      (1..).each do |index|
        socket.send("#{index} #{current_timestamp_ms}", 0, server_host, server_port)
        puts "Sent packet #{index} at #{current_timestamp_ms}ms"
        sleep(period_s)
      end
    end

    private

      attr_reader \
        :socket,
        :server_host,
        :server_port,
        :period_s

      def current_timestamp_ms
        DateTime.now.strftime("%Q").to_i
      end
  end
end

UDP::Client.new(
  host: "127.0.0.1",
  port: 8002,
  server_host: "127.0.0.1",
  server_port: 8000
).run

