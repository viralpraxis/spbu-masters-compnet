# frozen_string_literal: true

require "socket"
require "ipaddr"

module Executor
  module_function

  def eval(interface:)
    unless (ifaddr_list = Socket.getifaddrs.select { |ifaddr| ifaddr.name == interface && (ifaddr.addr.ipv4? || ifaddr.addr.ipv6?) }).size > 0
      puts "Unable to find network interface #{interface}"

      exit 1
    end

    ifaddr_list.map do |ifaddr|
      proto = if ifaddr.addr.ipv4?
        "IPv4"
      else
        "IPv6"
      end

      [
        proto,
        format_sockadd(ifaddr.addr.inspect_sockaddr),
        ifaddr.netmask.inspect_sockaddr
      ]
    end
  end

  def format_sockadd(sockadd)
    sockadd.split(":").first
  end
end

interface = ARGV[0]

if !interface || interface.size == 0
  puts "provider interface identifier as argument"

  exit 1
end

result = Executor.eval(interface: interface)

sep = "\t\t"
print %w[proto address netmask].join(sep) + "\n"

result.each do |item|
  print item.join(sep)
  print("\n")
end