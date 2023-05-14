# frozen_string_literal: true

module RIP
  class Host
    TERMINATE_MESSAGE = "¯\_(ツ)_/¯"

    Table = Struct.new(:records, keyword_init: true)
    Record = Struct.new(:destination, :next_hop, :metric, keyword_init: true) do
      def to_s
        "dest: #{destination}, next_hop: #{next_hop}, metric: #{metric}"
      end
    end

    attr_reader :name, :table

    def initialize(spec, network:)
      @ip_address = spec.ip_address
      @network = network

      @should_send = true
      @sleep_for = 5 # 5 seconds, 30 in original RIP proto
      @table = Table.new(records: [])
      @mutex = Mutex.new
      @iteration = 0

      initialize_table
    end

    def start
      start_receiver
      start_sender
    end

    def print_table
      table.records.each do |record|
        puts record
      end
      puts
    end

    def exit_gracefully
      @should_send = false

      network.shutdown_self(self.ip_address)

      worker_receiver.join
      worker_sender.join
    end

    attr_reader :ip_address

    private

      attr_reader \
        :table, \
        :network

      attr_reader \
        :worker_sender, \
        :worker_receiver, \
        :sleep_for, \
        :should_send, \
        :mutex

      def start_receiver
        @worker_receiver = Thread.new do
          while @should_send do
            from, table = network.receive_message(self.ip_address)
            break if from == Host::TERMINATE_MESSAGE

            process_message(from, table)
          end
        end
      end

      def start_sender
        @worker_sender = Thread.new do
          while @should_send
            sleep sleep_for + rand * 3.5

            network.broadcast(self.ip_address, self.table)
          end
        end
      end

      def atomic(&block)
        mutex.synchronize(&block)
      end

      def process_message(from, table)
        # puts "#{ip_address}: received #{table.class} from #{from}"

        atomic do
          @iteration += 1
          table.records.each do |record|
            next if record.destination == ip_address

            if (self_record = find_record_for(record.destination))
              if self_record.metric > record.metric + 1
                self_record.next_hop = from
                self_record.metric = record.metric + 1
              end
            else
              new_record = record.dup
              new_record.next_hop = from
              new_record.metric += 1
              @table.records << new_record
            end
          end

          puts "host: #{ip_address}, iteration: #{@iteration}"
          print_table
          puts "\n"
        end
      end

      def find_record_for(destination)
        @table.records.each do |record|
          return record if record.destination == destination
        end

        nil
      end

      def initialize_table
        @table.records << Record.new(
          destination: self.ip_address, next_hop: self.ip_address, metric: 0
        )
      end
  end
end
