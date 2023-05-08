# frozen_string_literal: true

require "socket"

module GBN
  class Server
    def initialize(host:, port:)
      @host = host
      @port = port

      @next_sequence_number = 0
    end

    def start
      puts "server: ready to receive"

      data = ""

      Socket.udp_server_loop(host, port) do |message, sender|
        index, chunk = message.split("\u0000")
        sleep 0.5

        break if chunk == nil || chunk.size == 0

        puts "Received chunk #{index}, expected #{next_sequence_number}"

        if index.to_i == @next_sequence_number
          sender.reply(next_sequence_number.to_s)
          @next_sequence_number += 1

          data = [data, chunk].join("")
        end
      end

      puts "data:"
      puts data
    end

    private

      attr_reader :host, :port, :next_sequence_number
  end
end

server = GBN::Server.new(host: "localhost", port: "8000")
server.start
