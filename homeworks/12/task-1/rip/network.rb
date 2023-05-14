# frozen_string_literal: true

module RIP
  class Network
    def initialize(configuration)
      @configuration = configuration
      @queues = {}

      initialize_queues
    end

    def broadcast(from, data)
      dest = configuration.hosts[from].links
      raise RuntimeError, "no hosts" if dest.empty?

      dest.each do |dest_addr|
        @queues[dest_addr] << [from, data]
      end
    end

    def receive_message(from)
      @queues[from].pop
    end

    def shutdown_self(from)
      @queues[from] << Host::TERMINATE_MESSAGE
    end

    private

      attr_reader :configuration, :queue

      def initialize_queues
        configuration.hosts.each do |ip_address, host|
          @queues[ip_address] = Thread::Queue.new
        end
      end
  end
end
