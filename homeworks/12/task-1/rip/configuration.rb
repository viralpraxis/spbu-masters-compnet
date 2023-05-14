# frozen_string_literal: true

module RIP
  class Configuration
    Host = Struct.new(:ip_address, :links, keyword_init: true)

    def initialize(data)
      @data = transform_data(data["hosts"])
    end

    def hosts
      @data
    end

    private

      def transform_data(data)
        {}.tap do |hash|
          data.each do |host_spec|
            host = Host.new(host_spec)
            hash[host.ip_address] = host
          end
        end
      end
  end
end
