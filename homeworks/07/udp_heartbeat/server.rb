# frozen_string_literal: true

require "socket"
require "time"

module UDP
  class Server
    Record = Struct.new(:index, :original_timestamp, :timestamp) do
      def initialize(message, timestamp:)
        index, original_timestamp = message.split(" ")

        self.index = index
        self.original_timestamp = original_timestamp.to_i
        self.timestamp = timestamp
      end
    end

    def initialize(host:, port:, inactive_client_threshold_ms: 750)
      @host = host
      @port = port
      @inactive_client_threshold_ms = inactive_client_threshold_ms

      @clients_data = {}
    end

    def run
      spawn_observer

      Socket.udp_server_loop(host, port) do |message, sender|
        key = sender.remote_address.inspect
        record = Record.new(message, timestamp: current_timestamp_ms)

        prev = clients_data[key]
        if !prev || prev.timestamp < record.timestamp
          clients_data[key] = record
        end
      end
    end

    private

      attr_reader \
        :host,
        :port,
        :inactive_client_threshold_ms,
        :clients_data

      def spawn_observer
        Thread.new do
          loop do
            ts = current_timestamp_ms
            data = clients_data.clone
            data.each do |k, v|
              if v.timestamp + inactive_client_threshold_ms < ts
                puts "Client #{k} seems to be inactive"
              end
            end
            sleep(0.1)
          end
        end
      end

      def current_timestamp_ms
        DateTime.now.strftime("%Q").to_i
      end
  end
end

UDP::Server.new(
  host: "127.0.0.1",
  port: 8000
).run