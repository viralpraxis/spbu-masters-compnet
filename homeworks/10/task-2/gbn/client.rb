# frozen_string_literal: true

require "socket"
require "timeout"

module GBN
  class Client
    CHUNK_SIZE = 64

    def initialize(host:, port:, n: 3, ack_timeout: 1)
      @socket = UDPSocket.new.tap do |s|
        s.connect(host, port)
      end

      @n = n
      @ack_timeout = ack_timeout

      @window_start = 0
      @last_sent_chunk = 0
      @last_received_ack = nil

      @ack_timeout_failed = nil
    end

    def transmit(data)
      chunks = data.scan(/.{1,#{Regexp.quote(CHUNK_SIZE.to_s)}}/)

      puts "--- TRANSMISSION STARTED ---"
      puts "total chunks count: #{chunks.size}"
      puts "\n"

      sent_on_current_iteration = false

      loop do
        break if @window_start >= chunks.size

        if @ack_timeout_failed
          @last_sent_chunk = window_start
          @ack_timeout_failed = nil
        elsif @ack_timeout_failed == false
          @window_start += 1
          @ack_timeout_failed = nil
          send_async_wait_ack(@window_start, chunks[@window_start])
          sent_on_current_iteration = true
        elsif @last_sent_chunk <= window_start
          send_async_wait_ack(@window_start, chunks[@window_start])
          sent_on_current_iteration = true
          @last_sent_chunk += 1
        elsif @last_sent_chunk < window_start + n - 1
          send_sync(@last_sent_chunk, chunks[@last_sent_chunk])
          sent_on_current_iteration = true
          @last_sent_chunk += 1
        end

        break if @window_start >= chunks.size

        print_progress # if sent_on_current_iteration
        sent_on_current_iteration = false

        sleep 0.1
      end

      socket.send("done", 0)
      socket.close
    end

    private

      attr_writer :ack_timeout_failed

      attr_reader \
        :socket, \
        :n, \
        :ack_timeout, \
        :window_start, \
        :last_sent_chunk, \
        :last_received_ack

      def print_progress
        puts "window: [#{window_start}, #{window_start + n - 1}], last-sent-chunk: #{last_sent_chunk}"
      end

      def send_sync(chunk_index, chunk)
        socket.send("#{chunk_index}\u0000#{chunk}", 0)
      end

      def send_async_wait_ack(chunk_index, chunk)
        Thread.new do
          socket.send("#{chunk_index}\u0000#{chunk}", 0)

          Timeout.timeout(ack_timeout) do
            msg, src = socket.recvfrom(16)
            self.ack_timeout_failed = false
            puts "received ACK for chunk #{msg}"
          end

          true
        rescue
          puts "lost ACK"
          self.ack_timeout_failed = true
        end
      end
  end
end

client = GBN::Client.new(host: "localhost", port: 8000, n: (ARGV[1] || "3").to_i)
client.transmit(File.read(ARGV[0]))
