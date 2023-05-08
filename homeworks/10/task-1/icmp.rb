# frozen_string_literal: true

require "timeout"
require "socket"
require "resolv"

module ICMP
  module Status
    CODE_TO_STATUS = {
      0 => "ECHO_REPLY",
      # 1, 2 -- unassigned
      3 => "DISTINATION_UNREACHABLE",
      # 4 -- deprecated
      5 => "REDIRECT_MESSAGE",
      # 6, 7 -- depracated
      8 => "ECHO_REQUEST",
      11 => "TIME_EXCEEDED",
      12 => "BAD_IP_HEADER"
    }.freeze

    def from_value(value)
      CODE_TO_STATUS.fetch(value.to_i, "UNKNOWN")
    end
  end
end

class ICMPPinger
  include Socket::Constants
  include ICMP::Status

  class Stats
    def initialize
      @items = []
      @lost_packets_count = 0
    end

    def add(item)
      @items << item
    end

    def report_lost_packet
      @lost_packets_count += 1
    end

    def max = @items.max || 0
    def min = @items.min || 0
    def avg = @items.sum.to_f./(@items.size)
    def lost_packets_ratio = (@lost_packets_count.to_f / @items.size).round(2)

    def to_s
      "(min: #{min}, max: #{max}, avg: #{avg.round(2)}, lost: #{lost_packets_ratio}%)"
    end
  end

  def initialize(host, timeout: 1, period: 1)
    @host = host
    @timeout = timeout
    @period = period

    @stats = Stats.new
  end

  def run
    socket = Socket.open(Socket::PF_INET, Socket::SOCK_DGRAM, Socket::IPPROTO_ICMP)

    puts "PING #{host} (#{resolved_ip})"

    seq = 0

    loop do
      seq += 1

      sent_at = Time.now
      timestamp_sent_at = (sent_at.hour * 3600 + sent_at.min * 60 + sent_at.sec) * 1000 + sent_at.tv_nsec / 1_000_000
      sent = send_ping(socket, host, seq, [timestamp_sent_at].pack("N"))

      timestamp_received_at, rcvd, icmp_code = receive_ping(socket, timeout)
      if rcvd
        timestamp_received_at = (timestamp_received_at.hour * 3600 + timestamp_received_at.min * 60 + timestamp_received_at.sec) * 1000 + timestamp_received_at.tv_nsec / 1_000_000
        timestamp_sent_at = rcvd[8, 4].unpack1("N")
        latency = timestamp_received_at - timestamp_sent_at

        stats.add(latency)
        puts "#{rcvd.size} bytes from #{host}, time: #{latency}, #{stats}, ICMP code: #{from_value(icmp_code)}"
      else
        stats.report_lost_packet
      end

      sleep period
    end

    socket.close
  end

  private

  attr_reader :host, :timeout, :period, :stats

  def resolved_ip
    @resolved_ip ||= Resolv.getaddress(host)
  end

  def checksum(data)
    length = data.length
    num_short = length / 2
    check = data.unpack("n#{num_short}").sum
    check += data[length - 1, 1].unpack1("C") << 8 if (length % 2).positive?
    check = (check >> 16) + (check & 0xffff)

    (~((check >> 16) + check) & 0xffff)
  end

  def send_ping(socket, host, seq, data)
    id = 0
    checksum = 0
    icmp_packet = [8, 0, checksum, id, seq].pack("C2 n3") << data
    checksum = checksum(icmp_packet)
    icmp_packet = [8, 0, checksum, id, seq].pack("C2 n3") << data
    saddr = Socket.pack_sockaddr_in(0, host)
    socket.send(icmp_packet, 0, saddr)

    icmp_packet
  end

  def receive_ping(socket, timeout)
    io_array = select([socket], nil, nil, timeout)
    return nil, nil if io_array.nil? || io_array[0].empty?

    data = socket.recv(32)
    timestamp_received_at = Time.now
    if data.size == 32
      return timestamp_received_at, nil unless data.unpack1("C") == 0x45

      offset = 20
    else
      offset = 0
    end

    icmp_type, icmp_code = data[0 + offset, 2].unpack("C2")
    if icmp_type.zero? && icmp_code.zero?
      _echo_reply_id, echo_reply_seq = data[4 + offset, 4].unpack("n2")
      return timestamp_received_at, data[offset..], icmp_type
    end
    [timestamp_received_at, nil, icmp_type]
  end
end

icmp_pinger = ICMPPinger.new(ARGV[0])
icmp_pinger.run
