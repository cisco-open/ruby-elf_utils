# encoding: ASCII-8BIT
# frozen_string_literal: true

module ElfUtils::Types
  RSpec.describe SLEB128 do
    [[0, "\0"],
      [2, "\2"],
      [-2, "\x7e"],
      [127, "\xff\x00"],
      [-127, "\x81\x7f"],
      [128, "\x80\x01"],
      [-128, "\x80\x7f"],
      [129, "\x81\x01"],
      [-129, "\xff\x7e"]].each do |value, encoded_value|
      it "pack(%p) => %p" % [value, encoded_value] do
        expect(described_class.pack(value)).to eq(encoded_value)
      end

      it "unpack(%p) => %p" % [encoded_value, value] do
        unpacked = described_class.unpack(encoded_value)
        expect(unpacked).to eq(value)
      end
    end
  end
end
