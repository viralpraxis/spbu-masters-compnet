# frozen_string_literal: true

require "yaml"

require_relative "configuration"
require_relative "network"
require_relative "host"

raw_configuration = YAML.load_file("#{File.expand_path File.dirname(__FILE__)}/configuration.yml")

configuration = RIP::Configuration.new(raw_configuration)
network = RIP::Network.new(configuration)

# hosts = []
# configuration.hosts.each do |host_spec|
#   hosts << RIP::Host.new(host_spec)
# end

hosts = []
configuration.hosts.each_value do |host_spec|
  hosts << RIP::Host.new(host_spec, network: network)
end

hosts.each do |host|
  host.start
end

sleep 20

hosts.each do |host|
  host.exit_gracefully
end

puts "--- FINAL STATE"
hosts.each do |host|
  puts "host #{host.ip_address}"
  host.print_table
end

puts :OK
