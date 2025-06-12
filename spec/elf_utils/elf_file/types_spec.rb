# encoding: ASCII-8BIT

module ElfUtils
  RSpec.describe ElfFile do
    describe "#type" do
      extend CTypes::Helpers

      # We do not currently apply relocation sections, as a result object
      # files fail this test.  This is because we'd need to apply the
      # .rel.debug_info section to .debug_info to get the correct
      # DW_FORM_STRP offsets.  Without relocation, they all contain offset 0.
      #
      # We also only use the full executable binaries because the other files
      # may not have all the types we're looking for.
      context_for_each_executable do |path, endian|
        # we decode all the base types with the endian of the elf file, so
        # we're going to create endianized instances of all of our base types
        # to make testcases easier to write.
        int8 = CTypes::Helpers.int8.with_endian(endian)
        int16 = CTypes::Helpers.int16.with_endian(endian)
        int32 = CTypes::Helpers.int32.with_endian(endian)
        int64 = CTypes::Helpers.int64.with_endian(endian)
        uint8 = CTypes::Helpers.uint8.with_endian(endian)
        uint16 = CTypes::Helpers.uint16.with_endian(endian)
        uint32 = CTypes::Helpers.uint32.with_endian(endian)
        uint64 = CTypes::Helpers.uint64.with_endian(endian)
        uintptr = (path.include?("_64") ? uint64 : uint32)

        tlv = struct do
          name "tlv"
          endian(endian)
          attribute :type, uint32
          attribute :len, uint32
          attribute :value, array(uint8, 0)
        end

        my_bitfield = if endian == :little
          bitfield do
            field :a, offset: 0, bits: 1
            field :b, offset: 1, bits: 2, signed: true
            field :c, offset: 8, bits: 1
          end
        else
          bitfield do
            field :a, offset: 31, bits: 1
            field :b, offset: 29, bits: 2, signed: true
            field :c, offset: 23, bits: 1
          end
        end.with_endian(endian)

        [
          # base types
          ["char", int8],
          ["short", int16],
          ["int", int32],
          ["long", (/_64/.match?(path) ? int64 : int32)],
          ["long long", int64],
          ["unsigned char", uint8],
          ["unsigned short", uint16],
          ["unsigned int", uint32],
          ["unsigned long", (/_64/.match?(path) ? uint64 : uint32)],
          ["unsigned long long", uint64],

          # arrays
          ["unsigned int[16]", array(uint32, 16)],
          ["unsigned char[16]", array(uint8, 16)],
          ["char[16]", string(16)],
          ["char[10][20]", array(string(20), 10)],
          ["char[10][20][30]", array(array(string(30), 20), 10)],
          ["unsigned int[3][4][5]", array(array(array(uint32, 5), 4), 3)],

          # structs
          ["struct tlv", tlv],
          ["struct nested",
            struct {
              name "nested"
              endian endian
              attribute :parent, uint32
              attribute :anon_struct, struct {
                endian endian
                attribute :nested_anon_int, int32
              }
              attribute :anon_union, union {
                endian endian
                member :a, int32
                member :b, int8
              }
              attribute :child, tlv
            }],
          ["struct with_padding",
            struct {
              name "with_padding"
              endian endian
              attribute :x, int16
              pad 2
              attribute :y, int32
            }],
          ["struct with_self_pointer",
            struct {
              name "with_self_pointer"
              endian endian
              attribute :next, uintptr
              attribute :id, int32
              # for 64-bit platforms, this struct gets padded
              pad(4) if uintptr.size == 8
            }],
          ["struct with_unnamed_fields",
            struct {
              name "with_unnamed_fields"
              endian endian
              attribute union(a: int32).with_endian(endian)
            }],
          ["struct with_bitfield",
            struct {
              name "with_bitfield"
              endian endian
              attribute my_bitfield
            }],
          ["struct tail_padded",
            struct {
              name "tail_padded"
              endian endian
              attribute :a, uint8
              pad(3)
            }],

          # unions
          ["union simple",
            union {
              endian endian
              member :id, uint32.with_endian(endian)
              member :buf, array(uint8.with_endian(endian), 32)
            }],
          ["union complex",
            union(
              id: uint32,
              tlv: tlv,
              anon_struct: struct(nested_anon_int: int32).with_endian(endian),
              anon_union: union(a: int32,
                b: int8).with_endian(endian)
            ).with_endian(endian)],

          # typedefs
          ["tlv", tlv],

          # enums
          ["enum enum_uint32", enum(uint32, {zero: 0, one: 1, three: 3})]
        ].each do |name, type|
          it "elf_file.type(%p) => %p" % [name, type] do
            expect(elf_file.type(name)).to eq(type)
          end
        end

        it "handles variable length array DIEs" do
          var_die = elf_file
            .debug_info
            .dies
            .find { |d| d[:name] == "array_variable_length" }
          type_die = var_die[:type]
          expect(type_die.ctype).to eq(CTypes.array(uint32))
        end
      end
    end
  end
end
