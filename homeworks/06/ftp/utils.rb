# frozen_string_literal: true

module Utils
    module_function

    def parse227(resp)
      if !resp.start_with?("227")
        raise ArgumentError, resp
      end

      m = /\((?<host>\d+(?:,\d+){3}),(?<port>\d+,\d+)\)/.match(resp)

      host = m["host"].tr(",", ".")
      port = m["port"].split(/,/).map(&:to_i).inject { |x, y| (x << 8) + y }

      return [host, port]
    end
end