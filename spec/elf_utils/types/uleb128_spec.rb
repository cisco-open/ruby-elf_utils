# encoding: ASCII-8BIT
# frozen_string_literal: true

module ElfUtils::Types
  RSpec.describe ULEB128 do
    [[0, "\0"],
      [1, "\1"],
      [0x7f, "\x7f"],
      [0x98765, "\xe5\x8e\x26"],
      [0x8000000000000000, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x01"]].each do |value, encoded_value|
      it "pack(%p) => %p" % [value, encoded_value] do
        expect(described_class.pack(value)).to eq(encoded_value)
      end

      it "unpack(%p) => %p" % [encoded_value, value] do
        expect(described_class.unpack(encoded_value)).to eq(value)
      end
    end
  end
end
