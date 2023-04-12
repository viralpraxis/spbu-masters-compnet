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
    RTTStats = Class.new do
      def initialize
        @records = []
        @missing_counter = 0
      end

      def add(rtt_entry)
        @records << rtt_entry
      end

      def add_missing
        @missing_counter += 1
      end

      def to_s
        [min, average, max, lost_percentage].map { |value| value.round(2) }.join("/")
      end

      private

        attr_reader :records, :missing_counter

        def average; records.sum.to_f / records.length; end

        def min; records.min; end

        def max; records.max; end

        def lost_percentage; missing_counter.to_f / (records.length + missing_counter) * 100; end
    end
    private_constant :RTTStats

    def initialize(host:, port:, server_host:, server_port:, pings_count: 10, timeout: 1.second)
      @socket = UDPSocket.new.tap do |udp_socket|
        udp_socket.bind(host, port)
      end
      @server_host = server_host
      @server_port = server_port
      @pings_count = pings_count
      @timeout = timeout

      @rtt_stats = RTTStats.new
    end

    def run
      puts "Ping #{server_host}:#{server_port} (min/avg/max/lost%)"

      (1..pings_count).each do |i|
        Timeout.timeout(timeout) do
          socket.send("ping #{i} #{current_timestamp_ms}", 0, server_host, server_port)

          loop do
            message, _ = socket.recvfrom(1024)
            _, index, ts = message.split(" ")
            if index == i.to_s
              rtt_stats.add(current_timestamp_ms - ts.to_i)
              puts "Ping #{i} #{rtt_stats}"
              break
            end
          end
        end
      rescue Timeout::Error
        rtt_stats.add_missing
        puts "Request timed out"
      end
    end

    private

      attr_reader \
        :socket,
        :server_host,
        :server_port,
        :pings_count,
        :timeout,
        :rtt_stats

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

