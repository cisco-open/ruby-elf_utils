# encoding: ASCII-8BIT
# frozen_string_literal: true

require "ctypes"
require "elf_utils/elf_utils" ## for unpack_one

module ElfUtils::Types::ULEB128
  extend CTypes::Type

  # declare the underlying DRY type; it must have a default value, and may
  # have constraints set
  @dry_type = Dry::Types["integer"].default(0)

  # as this is a dynamically sized type, let's set size to be the minimum size
  # for the type (1 byte), and ensure .fixed_size? returns false
  @size = 1
  def self.fixed_size?
    false
  end

  def self.size
    @size
  end

  def self.greedy?
    false
  end

  # provide a method for packing the ruby value into the binary representation
  def self.pack(value, endian: default_endian, validate: true)
    return "\0" if value == 0
    buf = +""
    while value != 0
      byte = (value & 0x7f)
      value >>= 7
      byte |= 0x80 if value != 0
      buf << byte
    end
    buf
  end

  # provide a method for unpacking an instance of this type from a String, and
  # returning both the unpacked value, and any unused input
  def self.unpack_one_ruby(buf, endian: default_endian)
    value = 0
    shift = 0
    len = 0
    buf.each_byte do |b|
      len += 1
      value |= ((b & 0x7f) << shift)
      return value, buf.byteslice(len...) if (b & 0x80) == 0
      shift += 7
    end
    raise TerminatorNotFoundError
  end
end
