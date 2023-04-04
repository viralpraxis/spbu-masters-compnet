# frozen_string_literal: true

require "socket"
require 'optparse'

require_relative "utils"
require_relative "commands"

class Dispatcher
  def initialize(options)
    @client = Client.new(options)
  end

  def run
    current_directory = nil

    loop do
      raw_dir = client.pwd
      current_directory = raw_dir.split(" ")[1].tr("\"", "")
      print(current_directory + ": ")

      input = $stdin.readline.strip.tr("\n", "")
      items = input.split(" ")

      if input.strip.size == 0
        next
      end

      if items[0] == "ls"
        client.list
      elsif items[0] == "cd" && items.size == 2
        client.cwd(items[1])
      elsif items[0] == "get" && items.size == 3
        client.get(source: items[1], dest: items[2])
      elsif items[0] == "put" && items.size == 3
        client.put(source: items[1], dest: items[2])
      else
        puts "Unsupported command or invalid syntax"
      end
    end
  rescue StandardError => e
    puts e
    client.finalize
  end

  private

    attr_reader :client
end

class Client
  def initialize(options)
    @options = options
    @socket = TCPSocket.new(options.host, options.port)

    Commands.readlines(socket)
    Commands.user(socket, username: options.username)
    Commands.pass(socket, password: options.password)

    puts :CONNECTED
  end

  def finalize
    socket&.close rescue nil
  end

  def cwd(dest)
    Commands.cwd(socket, destination: dest)
  end

  def pwd
    Commands.pwd(socket)
  end

  def list
    host, port = Utils.parse227(Commands.pasv(socket))
    data_socket = TCPSocket.new(host, port)
    Commands.ls(socket)

    loop do
      puts data_socket.readline
    rescue EOFError
      data_socket.close rescue nil
      socket.readline
      break
    end
  end

  def put(source:, dest:)
    host, port = Utils.parse227(Commands.pasv(socket))
    data_socket = TCPSocket.new(host, port)
    puts "[INFO] opened TCP connection with #{host}/#{port}"
    Commands.stor(socket, path: dest)

    file = File.open(source, "r")

    loop do
      data_socket.print(file.readline)
    rescue EOFError
      data_socket.close rescue nil
      file.close rescue nil
      socket.readline # get operation status
      break
    end
  end

  def get(source:, dest:)
    host, port = Utils.parse227(Commands.pasv(socket))
    data_socket = TCPSocket.new(host, port)
    puts "[INFO] opened TCP connection with #{host}/#{port}"
    Commands.retv(socket, path: source)

    file = File.open(dest, "w")

    loop do
      file.write(data_socket.readline)
    rescue EOFError
      data_socket.close rescue nil
      file.close rescue nil
      socket.readline # get operation status
      break
    end
  end

  private

    attr_reader :options, :socket
end

Options = Struct.new(:host, :port, :username, :password)
options = Options.new
OptionParser.new do |opts|
  opts.banner = "Usage: ruby client.rb [options]"

  opts.on("--host=HOST", "FTP host") do |value|
    options.host = value
  end

  opts.on("--port=PORT", "FTP port") do |value|
    options.port = value
  end

  opts.on("--username=USERNAME", "Username") do |value|
    options.username = value
  end

  opts.on("--password=PASSWORD", "Password") do |value|
    options.password = value
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!


# defaults
# options.host ||= "localhost"
# options.port ||= "21"
# options.username ||= "viralpraxis"
# options.password ||= "818a62c5b5cb5ff5bb32d9e2d66f5cb0"

Dispatcher.new(options).run