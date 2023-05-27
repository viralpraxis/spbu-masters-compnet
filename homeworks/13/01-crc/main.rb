# frozen_string_literal: true

require_relative "crc8"

def transmit(data)
  data_with_checksum = []

  data.each_slice(5).to_a.map.with_index do |slice, index|
    slice_with_chechsum = CRC8.pack(slice)

    if rand < 0.1
      puts "[info]: changed byte at chunk #{index + 1}"
      random = Random.new
      index_to_change = random.rand(slice_with_chechsum.size - 1)
      # incr or decr to change bits
      # intentionally not flipping single bit to simulate major data corruption
      if slice_with_chechsum[index_to_change] == 255
        slice_with_chechsum[index_to_change] -= 1
      else
        slice_with_chechsum[index_to_change] += 1
      end
    end

    data_with_checksum = data_with_checksum.concat(slice_with_chechsum)
  end

  data_with_checksum
end

def decode(data)
  index = 0

  data.each_slice(6).to_a.each do |slice|
    index += 1

    is_checksum_correct = CRC8.check(slice)

    output_data = [
      "chunk:", index,
      "payload:", slice[0...slice.size - 1].inspect,
      "crc8:", slice[slice.size-1],
      "correct:", is_checksum_correct
    ]

    output_data = output_data.concat(["( actual:", CRC8.calculate(slice[0...slice.size - 1]), ")"]) unless is_checksum_correct

    puts output_data.join(" ")
  end
end

data = $stdin.read.bytes
received = transmit(data)
decode(received)
