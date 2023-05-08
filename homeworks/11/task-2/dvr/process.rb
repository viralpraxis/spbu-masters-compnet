# frozen_string_literal: true

module DVR
  class Process
    TERMINATE_MESSAGE = "¯\_(ツ)_/¯"

    attr_reader :name, :table

    def initialize(name, table, bus:)
      @name = name
      @initial_table = table
      @table = table
      @nodes = table.keys
      @bus = bus

      @should_send = true
      @throttler = 0.5 + rand

      @table[name] = 0
      @last_update_from = {}
      @mutex = Mutex.new

      @cost_changed = nil
    end

    def start
      start_receiver
      start_sender
    end

    def update_route(node, cost:)
      raise "Unexpected node" unless nodes.include?(node)

      atomic do
        @table = @initial_table
        @table[node] = cost
        @table[name] = 0
      end
    end

    def exit_gracefully
      bus.send_message(name, name, TERMINATE_MESSAGE)
      @should_send = false

      worker_receiver.join
      worker_sender.join
    end

    private

      attr_reader \
        :nodes, \
        :bus, \
        :worker_receiver, \
        :worker_sender, \
        :throttler, \
        :last_update_from, \
        :mutex

      def start_receiver
        @worker_receiver = Thread.new do
          while @should_send do
            from, message, flags = bus.receive_message(name)
            break if message == TERMINATE_MESSAGE

            process_message(from, message, flags)
          end
        end
      end

      def start_sender
        @worker_sender = Thread.new do
          while @should_send
            atomic do
              nodes.dup.each do |node|
                bus.send_message(self.name, node, table)
              end
            end

            sleep throttler
          end
        end
      end

      def process_message(from, message, flags)
        puts "[#{name}]: received #{message} from #{from}"

        atomic do
          message.dup.each do |node, cost|
            if table[node] && table[node] > cost + table[from]
              table[node] = cost + table[from]
              last_update_from[node] = from
            elsif !table[node]
              table[node] = cost + table[from]
              last_update_from[node] = from
            end
          end
        end
      end

      def atomic
        mutex.lock

        yield
      ensure
        mutex.unlock
      end
  end
end
