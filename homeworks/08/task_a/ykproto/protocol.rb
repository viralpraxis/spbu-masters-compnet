# frozen_string_literal: true

require "socket"
require "timeout"

require_relative "ext"

module YKProto
  END_OF_TRANSMISSION_MESSAGE = [0x0, 0x0, 0x0].freeze
  ACK_FLAG = 0
  MSG_FLAG = 1

  class Client
    MAX_PACKET_SIZE = 1024

    Packet = Struct.new(:header, :message, keyword_init: true)
    PacketHeader = Struct.new(:state, :type, keyword_init: true)

    def initialize(to:, timeout: 1.second, lost_packets_ratio: 0.3)
      @to = to
      @timeout = timeout
      @lost_packets_ratio = lost_packets_ratio

      @socket = UDPSocket.new
      @state = 0x0
    end

    def send_data(data)
      loop do
        status = with_timeout(timeout) do
          if rand > lost_packets_ratio
            socket.send([state, *data].pack("C*"), 0, to[:host], to[:port])
            puts "sent #{data}"
          end

          message, _ = socket.recvfrom(MAX_PACKET_SIZE)
          packet = parse_packet(message)
          puts packet

          if packet.header.type == ACK_FLAG
            if packet.header.state != state
              :timeout
            else
              :ok
            end
          elsif packet.header.type == MSG_FLAG
            puts "Received message #{packet.message.pack("C*")}"
            :ok
          else
            puts "[error]: unexpected packet type #{packet.header.type}"
            :ok
          end
        end

        break unless status == :timeout
      end

      next_state!
    end

    def end_transmission
      socket.send YKProto::END_OF_TRANSMISSION_MESSAGE.pack("C*"), 0, to[:host], to[:port]

      with_timeout(5.seconds) do
        loop do
          message, _ = socket.recvfrom(MAX_PACKET_SIZE)
          packet = parse_packet(message)

          if packet.message = END_OF_TRANSMISSION_MESSAGE
            break
          end
        end
      end
    end

    private

      attr_reader :to, :timeout, :lost_packets_ratio, :socket, :state

      def parse_packet(packet)
        packet.bytes.then do |payload|
          Packet.new(
            header: PacketHeader.new(
              state: payload[1],
              type: payload[0]
            ),
            message: payload[2..]
          )
        end
      end

      def with_timeout(timeout)
        begin
          Timeout.timeout(timeout) do
            yield
          end
        rescue Timeout::Error
          :timeout
        end
      end

      def next_state!
        @state = 0x1 - state
      end
  end

  class YKProto::Server
    def initialize(to:, lost_packets_ratio: 0.3)
      @to = to
      @lost_packets_ratio = lost_packets_ratio

      @state = 0x0
      @terminated = false
    end

    def receive
      Thread.new do
        puts "Server: ready to receive"
        Socket.udp_server_loop(to[:host], to[:port]) do |message, sender|
          if message.bytes[0] == state
            print message.bytes[1..].pack("C*")
            @state = 0x1 - state
          end

          if rand > lost_packets_ratio
            sender.reply([YKProto::ACK_FLAG, *message.bytes].pack("C*"))
          end

          if message.bytes == YKProto::END_OF_TRANSMISSION_MESSAGE
            with_timeout(5.seconds) do
              sender.reply(END_OF_TRANSMISSION_MESSAGE.pack("C*"))
            end

            break
          end
        end
      end
    end

    private

      attr_reader \
        :to,
        :lost_packets_ratio,
        :state,
        :terminated

        def with_timeout(timeout)
          begin
            Timeout.timeout(timeout) do
              yield
            end
          rescue Timeout::Error
            :timeout
          end
        end
  end
end