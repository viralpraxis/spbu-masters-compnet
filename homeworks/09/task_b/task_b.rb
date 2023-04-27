# frozen_string_literal: true

require "optparse"
require "socket"
require "timeout"

class Executor
  InvalidArgumentError = Class.new(StandardError)
  private_constant :InvalidArgumentError

  def initialize(options)
    @ip_address = options.fetch(:ip_address)
    @ports_range = options.fetch(:ports_range)
    @mode = options.fetch(:mode)

    validate_arguments!
  end

  def call
    range_data = @ports_range.split(":").map(&:to_i)


    puts "TCP scan started"
    (range_data[0]..range_data[1]).each do |port|
      tcp_port_open = is_port_open?(ip_address, port, proto: :tcp)
      if mode == "busy" && tcp_port_open || mode == "open" && !tcp_port_open
        puts "#{port}/TCP"
      end
    end
    puts "TCP scan ended"
    puts "UDP scan started"

    threads_count = 250
    threads = []
    threads_count.times do |i|
      index = i
      threads << Thread.new do
        (range_data[0] + i..range_data[1]).step(threads_count).each do |port|
          udp_port_open = is_port_open?(ip_address, port, proto: :udp)
          if udp_port_open && mode == "busy" || !udp_port_open && mode == "open"
            puts "#{port}/UDP"
          end
        end
      end
    end
    threads.each(&:join)
    puts "UDP scan ended"
  end

  private

    attr_reader :ip_address, :ports_range, :mode

    def is_port_open?(ip, port, proto: :tcp)
      if proto == :tcp
        check_tcp(ip, port)
      elsif proto == :udp
        check_udp(ip, port)
      else
        raise ArgumentError, "Unexpected proto #{proto}"
      end
    end

    # NOTE
    # just try to establish TCP connection, on failure
    # ruby will raise and we're done
    def check_tcp(ip, port)
      begin
        s = Socket.tcp(ip, port, connect_timeout: 5)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT
        return false
      rescue => e
        puts "Unexpected exception: #{e.class}: #{e.message}"
        return false
      end
    end

    # NOTE:
    # we can't really detect if UDP port is open or busy
    # so we adopt stategy stolen from nmap
    # results might be incorrect (at least sometims)
    def check_udp(ip, port)
      @udp_socket ||= UDPSocket.new

      begin
        Timeout.timeout(0.2) do # 0.2 for testing speed, should be higher
          @udp_socket.send "ping", 0, ip, port.to_i
          @udp_socket.recvfrom(10)
        end
      rescue Timeout::Error
        false
      end
    end

    def validate_arguments!
      unless ports_range.include?(":") && ports_range.split(":").size == 2
        raise InvalidArgumentError, "Invalid 'ports_range' format, expected 'start-port:end-port'"
      end

      raise InvalidArgumentError, "Invalid 'mode' format, expected 'busy' or 'open' values" unless %w[open busy].include?(mode)
    end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby task_b.rb [options]"

  opts.on("-a VALUE", "--ip-address VALUE", "Specified IP address") do |v|
    options[:ip_address] = v
  end

  opts.on("-r VALUE", "--ports-range VALUE", "Specified ports range") do |v|
    options[:ports_range] = v
  end

  opts.on("-m VALUE", "--mode VALUE", "Mode (either busy or open)") do |v|
    options[:mode] = v
  end
end.parse!

Executor.new(
  options
).call

