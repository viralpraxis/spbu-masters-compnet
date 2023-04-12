# frozen_string_literal: true

require "socket"

module UDP
  class Server
    LOST_PACKETS_RATIO = 0.2
    private_constant :LOST_PACKETS_RATIO

    def initialize(host:, port:)
      @host = host
      @port = port
    end

    def run
      Socket.udp_server_loop(host, port) do |message, sender|
        next if rand <= LOST_PACKETS_RATIO
        puts "Received '#{message}'"

        sender.reply(message.upcase)
      end
    end

    private

      attr_reader :host, :port
  end
end

UDP::Server.new(
  host: "127.0.0.1",
  port: 8000
).run