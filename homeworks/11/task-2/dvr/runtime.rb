# frozen_string_literal: true

require_relative "bus"
require_relative "process"

class DVR::Runtime
  def self.call
    new.call
  end

  def call
    processes.each(&:start)
    sleep 5

    report_results

    processes[0].update_route(nodes[3], cost: 3)
    processes[3].update_route(nodes[0], cost: 3)
    sleep 5
    report_results

    puts "terminating gracefully.."
    processes.each(&:exit_gracefully)
  end

  private

    def report_results
      puts
      puts "--- results:"

      processes.each do |process|
        puts [process.name, process.table].inspect
      end

      puts
    end

    def processes
      @processes ||= [
        initialize_process(nodes[0], { nodes[1] => 1, nodes[2] => 3, nodes[3] => 7 }),
        initialize_process(nodes[1], { nodes[0] => 1, nodes[2] => 1 }),
        initialize_process(nodes[2], { nodes[0] => 3, nodes[1] => 1, nodes[3] => 2 }),
        initialize_process(nodes[3], { nodes[0] => 7, nodes[2] => 2})
      ]
    end

    def nodes
      @nodes ||= %w[
        node-0
        node-1
        node-2
        node-3
      ]
    end

    def bus
      @bus ||= DVR::Bus.new(nodes)
    end

    def initialize_process(node, table)
      DVR::Process.new(node, table, bus: bus)
    end
end

DVR::Runtime.call
