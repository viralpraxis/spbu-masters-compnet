# frozen_string_literal: true

module YKProto
  module Checksum
    module_function

    # @param bytes -- raw message
    # @returns checksum
    def compute(bytes)
      result = 0

      bytes.each_slice(2).to_a.each do |bytepair|
        if bytepair.size == 1
          result += bytepair[0]
        else
          result += 255 * bytepair[0] + bytepair[1]
        end
      end

      result.digits(2 ** 8)[0..3].then do |value|
        return value[0..3] if value.size >= 4

        while value.size < 4
          value = [0b0, *value]
        end

        value
      end
    end

    # @param bytes -- raw message
    # @param value -- received checksum
    # @returns true iff checksum matches
    def check(bytes, value)
      compute(bytes).then do |result|
        [result == value, result]
      end
    end
  end
end