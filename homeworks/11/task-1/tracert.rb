# frozen_string_literal: true

require "timeout"
require "socket"
require "resolv"

class ICMPPinger
  include Socket::Constants

  RTTStats = Struct.new(:ip, :min, :max, :avg, keyword_init: true) do
    def to_s
      "min #{min.round(2)}ms, max #{max.round(2)}ms, avg #{avg.round(2)}ms"
    end
  end

  MAX_HOPS = 30

  def initialize(host, probes: 3, timeout: 1, period: 1)
    @host = host
    @probes = probes
    @timeout = timeout
    @period = period

    @resolved_ip_address = resolve_ip_address(host)
  end

  def run
    @socket = Socket.open(Socket::AF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
    # socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MINTTL, 0)

    puts "traceroute to #{host} (#{(@resolved_ip_address)})"

    ip_addr = @resolved_ip_address

    (1..MAX_HOPS).each do |seq|
      rtt_stats = do_probes(ttl_value: seq)

      if rtt_stats
        puts "#{seq}) #{resolve_domain_name(rtt_stats.ip.inspect_sockaddr)} (#{rtt_stats.ip.inspect_sockaddr}) #{rtt_stats}"

        return if rtt_stats.ip.inspect_sockaddr == @resolved_ip_address
      else
        puts "* * *"
      end
      # next

      # if source_addr
      #   # puts [timestamp_received_at, rcvd, icmp_code, source_addr].inspect
      #   puts ["#{seq})", source_addr.inspect_sockaddr, "1ms 2ms 3ms"].join(" ")

      #   if source_addr.inspect_sockaddr == @resolved_ip_address.to_s
      #     return
      #   end
      # else
      #   puts "#{seq}) * * *"
      # end

      # if rcvd
      #   timestamp_received_at = (timestamp_received_at.hour * 3600 + timestamp_received_at.min * 60 + timestamp_received_at.sec) * 1000 + timestamp_received_at.tv_nsec / 1_000_000
      #   timestamp_sent_at = rcvd[8, 4].unpack1("N")
      #   latency = timestamp_received_at - timestamp_sent_at
      # end
    end

    socket.close rescue nil
    (puts "#{MAX_HOPS} limit exceeded, couldn't reach #{host}") and exit 1
  end

  private

  attr_reader :host, :probes, :timeout, :period, :socket

  def do_probes(ttl_value:)
    host = @resolved_ip_address

    rtt_values = []
    source_addr = nil

    probes.times do
      timestamp_sent_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000
      sent = send_ping(socket, host, ttl_value, [timestamp_sent_at].pack("N"), ttl: ttl_value)

      timestamp_received_at, rcvd, icmp_code, source_addr = receive_ping(socket, timeout)
      # puts [ timestamp_received_at, rcvd, icmp_code, source_addr].inspect

      if source_addr
        timestamp_received_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000
        rtt_values << timestamp_received_at - timestamp_sent_at
      end
    end

    return nil if rtt_values.size.zero?

    RTTStats.new(
      ip: source_addr,
      min: rtt_values.min,
      max: rtt_values.max,
      avg: rtt_values.sum.to_f / rtt_values.size
    )
  end

  def resolve_ip_address(host)
    Resolv.getaddress(host)
  end

  def resolve_domain_name(ip_address)
    Resolv.getname(ip_address) rescue ip_address
  end

  def checksum(data)
    length = data.length
    num_short = length / 2
    check = data.unpack("n#{num_short}").sum
    check += data[length - 1, 1].unpack1("C") << 8 if (length % 2).positive?
    check = (check >> 16) + (check & 0xffff)

    (~((check >> 16) + check) & 0xffff)
  end

  def send_ping(socket, host, seq, data, ttl:)
    id = 0
    checksum = 0
    icmp_packet = [8, 0, checksum, id, seq].pack("C2 n3") << data
    checksum = checksum(icmp_packet)
    icmp_packet = [8, 0, checksum, id, seq].pack("C2 n3") << data
    saddr = Socket.pack_sockaddr_in(0, host)

    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, ttl)
    socket.send(icmp_packet, 0, saddr)

    icmp_packet
  end

  def receive_ping(socket, timeout)
    io_array = select([socket], [], [socket], timeout)
    return nil, nil if io_array.nil? || io_array[0].empty?

    data, remote_addr = socket.recvmsg(32, 0)
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
      return timestamp_received_at, data[offset..], icmp_type, remote_addr
    end

    [timestamp_received_at, nil, icmp_type, remote_addr]
  end
end


icmp_pinger = ICMPPinger.new(ARGV[0], probes: ARGV[1]&.to_i || 3)
icmp_pinger.run
