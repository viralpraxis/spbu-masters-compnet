# frozen_string_literal: true

module DVR
  class Bus
    UnknownNodeError = Class.new(StandardError)

    def initialize(nodes)
      @nodes = nodes

      initialize_queues
    end

    def send_message(from, to, message, flags = 0)
      raise UnknownNodeError, to unless queues[to]

      queues[to] << [from, message, flags]
    end

    def receive_message(mailbox)
      queues[mailbox].pop
    end

    private

      attr_reader :nodes, :queues

      def initialize_queues
        @queues = {}

        nodes.each do |node|
          queues[node] = Thread::Queue.new
        end
      end
  end
end
