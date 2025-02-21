# encoding: ASCII-8BIT
# frozen_string_literal: true

require "ctypes"

module ElfUtils::Types::SLEB128
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

  # provide a method for packing the ruby value into the binary representation
  def self.pack(value, endian: default_endian, validate: true)
    return "\0" if value == 0
    buf = +""
    done = false
    until done
      byte = (value & 0x7f)
      value >>= 7
      signed = byte & 0x40 != 0

      if (value == 0 && !signed) || (value == -1 && signed)
        done = true
      else
        byte |= 0x80
      end

      buf << byte
    end

    buf
  end

  # provide a method for unpacking an instance of this type from a String, and
  # returning both the unpacked value, and any unused input
  def self.unpack_one(buf, endian: default_endian)
    value = 0
    shift = 0
    len = 0
    terminated, sign_extend = buf.each_byte do |b|
      len += 1
      value |= ((b & 0x7f) << shift)
      shift += 7
      if (b & 0x80) == 0
        break [true, b & 0x40 != 0]
      end
    end
    raise TerminatorNotFoundError unless terminated

    value |= (~0 << shift) if sign_extend

    [value, buf.byteslice(len..)]
  end
end
