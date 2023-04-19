# frozen_string_literal: true

require_relative "ykproto/protocol"

Dispatcher = Module.new do
  SERVER_ADDRESS = { host: "0.0.0.0", port: 8000 }.freeze

  module_function

  def dispatch(mode, path = nil)
    if mode == "server"
      receiver = YKProto::Server.new(to: SERVER_ADDRESS)
      thrd = receiver.receive

      if path
        data = File.open(path, "r").read
        sleep(2)
        receiver.send(data)
      end

      thrd.join
    elsif mode == "client"
      sender = YKProto::Client.new(to: SERVER_ADDRESS)

      data = File.open(path, "r").read

      chunks = data.bytes.each_slice(15)
      chunks.each do |chunk|
        sender.send_data chunk
      end

      sender.end_transmission
    else
      raise ArgumentError, mode
    end
  end
end

Dispatcher.dispatch(ARGV[0], ARGV[1])
