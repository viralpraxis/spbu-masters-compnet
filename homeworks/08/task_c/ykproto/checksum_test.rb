# frozen_string_literal: true

require_relative "checksum"

def test_compute(bytes, result)
  value = YKProto::Checksum.compute(bytes)
  raise "Invalid result: expected #{result.inspect}, got #{value.inspect}" unless value == result

  puts "test check_check[#{bytes.inspect}, #{result.inspect}]: OK"
end

test_compute("".bytes, [0, 0, 0, 0])
test_compute("absdfsdwqe".bytes, [0, 6, 15, 2])
test_compute("cde".bytes, [0, 0, 102, 99])
test_compute("12я".bytes, [0, 191, 1, 1])
test_compute("__q2w34rdsfmewoirfj4w3e".bytes, [0, 188, 107, 4]