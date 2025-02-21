require "ctypes"
require_relative "uleb128"

module ElfUtils
  module Types::Dwarf
    extend CTypes::Helpers
    extend self

    UnitType = CTypes::Enum.new(Types::ULEB128, {
      compile: 0x01,
      type: 0x02,
      partial: 0x03,
      skeleton: 0x04,
      split_compile: 0x05,
      split_type: 0x06,
      lo_user: 0x80,
      hi_user: 0xff
    }).permissive

    Tag = CTypes::Enum.new(Types::ULEB128, {
      invalid: 0,
      array_type: 0x01,
      class_type: 0x02,
      entry_point: 0x03,
      enumeration_type: 0x04,
      formal_parameter: 0x05,
      imported_declaration: 0x08,
      label: 0x0a,
      lexical_block: 0x0b,
      member: 0x0d,
      pointer_type: 0x0f,
      reference_type: 0x10,
      compile_unit: 0x11,
      string_type: 0x12,
      structure_type: 0x13,
      subroutine_type: 0x15,
      typedef: 0x16,
      union_type: 0x17,
      unspecified_parameters: 0x18,
      variant: 0x19,
      common_block: 0x1a,
      common_inclusion: 0x1b,
      inheritance: 0x1c,
      inlined_subroutine: 0x1d,
      module: 0x1e,
      ptr_to_member_type: 0x1f,
      set_type: 0x20,
      subrange_type: 0x21,
      with_stmt: 0x22,
      access_declaration: 0x23,
      base_type: 0x24,
      catch_block: 0x25,
      const_type: 0x26,
      constant: 0x27,
      enumerator: 0x28,
      file_type: 0x29,
      friend: 0x2a,
      namelist: 0x2b,
      namelist_item: 0x2c,
      packed_type: 0x2d,
      subprogram: 0x2e,
      template_type_parameter: 0x2f,
      template_value_parameter: 0x30,
      thrown_type: 0x31,
      try_block: 0x32,
      variant_part: 0x33,
      variable: 0x34,
      volatile_type: 0x35,
      dwarf_procedure: 0x36,
      restrict_type: 0x37,
      interface_type: 0x38,
      namespace: 0x39,
      imported_module: 0x3a,
      unspecified_type: 0x3b,
      partial_unit: 0x3c,
      imported_unit: 0x3d,
      condition: 0x3f,
      shared_type: 0x40,
      type_unit: 0x41,
      rvalue_reference_type: 0x42,
      template_alias: 0x43,
      coarray_type: 0x44,
      generic_subrange: 0x45,
      dynamic_type: 0x46,
      atomic_type: 0x47,
      call_site: 0x48,
      call_site_parameter: 0x49,
      skeleton_unit: 0x4a,
      immutable_type: 0x4b
    }).permissive

    Form = CTypes::Enum.new(Types::ULEB128, {
      zero: 0,
      addr: 0x01,
      block2: 0x03,
      block4: 0x04,
      data2: 0x05,
      data4: 0x06,
      data8: 0x07,
      string: 0x08,
      block: 0x09,
      block1: 0x0a,
      data1: 0x0b,
      flag: 0x0c,
      sdata: 0x0d,
      strp: 0x0e,
      udata: 0x0f,
      ref_addr: 0x10,
      ref1: 0x11,
      ref2: 0x12,
      ref4: 0x13,
      ref8: 0x14,
      ref_udata: 0x15,
      indirect: 0x16,
      sec_offset: 0x17,
      exprloc: 0x18,
      flag_present: 0x19,
      strx: 0x1a,
      addrx: 0x1b,
      ref_sup4: 0x1c,
      strp_sup: 0x1d,
      data16: 0x1e,
      line_strp: 0x1f,
      ref_sig8: 0x20,
      implicit_const: 0x21,
      loclistx: 0x22,
      rnglistx: 0x23,
      ref_sup8: 0x24,
      strx1: 0x25,
      strx2: 0x26,
      strx3: 0x27,
      strx4: 0x28,
      addrx1: 0x29,
      addrx2: 0x2a,
      addrx3: 0x2b,
      addrx4: 0x2c
    }).permissive

    Attribute = CTypes::Enum.new(Types::ULEB128, {
      zero: 0,
      sibling: 0x01,
      location: 0x02,
      name: 0x03,
      ordering: 0x09,
      byte_size: 0x0b,
      bit_offset: 0x0c,
      bit_size: 0x0d,
      stmt_list: 0x10,
      low_pc: 0x11,
      high_pc: 0x12,
      language: 0x13,
      discr: 0x15,
      discr_value: 0x16,
      visibility: 0x17,
      import: 0x18,
      string_length: 0x19,
      common_reference: 0x1a,
      comp_dir: 0x1b,
      const_value: 0x1c,
      containing_type: 0x1d,
      default_value: 0x1e,
      inline: 0x20,
      is_optional: 0x21,
      lower_bound: 0x22,
      producer: 0x25,
      prototyped: 0x27,
      return_addr: 0x2a,
      start_scope: 0x2c,
      bit_stride: 0x2e,
      upper_bound: 0x2f,
      abstract_origin: 0x31,
      accessibility: 0x32,
      address_class: 0x33,
      artificial: 0x34,
      base_types: 0x35,
      calling_convention: 0x36,
      count: 0x37,
      data_member_location: 0x38,
      decl_column: 0x39,
      decl_file: 0x3a,
      decl_line: 0x3b,
      declaration: 0x3c,
      discr_list: 0x3d,
      encoding: 0x3e,
      external: 0x3f,
      frame_base: 0x40,
      friend: 0x41,
      identifier_case: 0x42,
      macro_info: 0x43,
      namelist_item: 0x44,
      priority: 0x45,
      segment: 0x46,
      specification: 0x47,
      static_link: 0x48,
      type: 0x49,
      use_location: 0x4a,
      variable_parameter: 0x4b,
      virtuality: 0x4c,
      vtable_elem_location: 0x4d,
      allocated: 0x4e,
      associated: 0x4f,
      data_location: 0x50,
      byte_stride: 0x51,
      entry_pc: 0x52,
      use_UTF8: 0x53,
      extension: 0x54,
      ranges: 0x55,
      trampoline: 0x56,
      call_column: 0x57,
      call_file: 0x58,
      call_line: 0x59,
      description: 0x5a,
      binary_scale: 0x5b,
      decimal_scale: 0x5c,
      small: 0x5d,
      decimal_sign: 0x5e,
      digit_count: 0x5f,
      picture_string: 0x60,
      mutable: 0x61,
      threads_scaled: 0x62,
      explicit: 0x63,
      object_pointer: 0x64,
      endianity: 0x65,
      elemental: 0x66,
      pure: 0x67,
      recursive: 0x68,
      signature: 0x69,
      main_subprogram: 0x6a,
      data_bit_offset: 0x6b,
      const_expr: 0x6c,
      enum_class: 0x6d,
      linkage_name: 0x6e,
      string_length_bit_size: 0x6f,
      string_length_byte_size: 0x70,
      rank: 0x71,
      str_offsets_base: 0x72,
      addr_base: 0x73,
      rnglists_base: 0x74,
      dwo_name: 0x76,
      reference: 0x77,
      rvalue_reference: 0x78,
      macros: 0x79,
      call_all_calls: 0x7a,
      call_all_source_calls: 0x7b,
      call_all_tail_calls: 0x7c,
      call_return_pc: 0x7d,
      call_value: 0x7e,
      call_origin: 0x7f,
      call_parameter: 0x80,
      call_pc: 0x81,
      call_tail_call: 0x82,
      call_target: 0x83,
      call_target_clobbered: 0x84,
      call_data_location: 0x85,
      call_data_value: 0x86,
      noreturn: 0x87,
      alignment: 0x88,
      export_symbols: 0x89,
      deleted: 0x8a,
      defaulted: 0x8b,
      loclists_base: 0x8c,

      MIPS_fde: 0x2001,
      MIPS_loop_begin: 0x2002,
      MIPS_tail_loop_begin: 0x2003,
      MIPS_epilog_begin: 0x2004,
      MIPS_loop_unroll_factor: 0x2005,
      MIPS_software_pipeline_depth: 0x2006,
      MIPS_linkage_name: 0x2007,
      MIPS_stride: 0x2008,
      MIPS_abstract_name: 0x2009,
      MIPS_clone_origin: 0x200a,
      MIPS_has_inlines: 0x200b,
      MIPS_stride_byte: 0x200c,
      MIPS_stride_elem: 0x200d,
      MIPS_ptr_dopetype: 0x200e,
      MIPS_allocatable_dopetype: 0x200f,
      MIPS_assumed_shape_dopetype: 0x2010,
      MIPS_assumed_size: 0x2011,

      sf_names: 0x2101,
      src_info: 0x2102,
      mac_info: 0x2103,
      src_coords: 0x2104,
      body_begin: 0x2105,
      body_end: 0x2106,
      GNU_vector: 0x2107,
      GNU_guarded_by: 0x2108,
      GNU_pt_guarded_by: 0x2109,
      GNU_guarded: 0x210a,
      GNU_pt_guarded: 0x210b,
      GNU_locks_excluded: 0x210c,
      GNU_exclusive_locks_required: 0x210d,
      GNU_shared_locks_required: 0x210e,
      GNU_odr_signature: 0x210f,
      GNU_template_name: 0x2110,
      GNU_call_site_value: 0x2111,
      GNU_call_site_data_value: 0x2112,
      GNU_call_site_target: 0x2113,
      GNU_call_site_target_clobbered: 0x2114,
      GNU_tail_call: 0x2115,
      GNU_all_tail_call_sites: 0x2116,
      GNU_all_call_sites: 0x2117,
      GNU_all_source_call_sites: 0x2118,
      GNU_locviews: 0x2137,
      GNU_entry_view: 0x2138,
      GNU_macros: 0x2119,
      GNU_deleted: 0x211a,
      GNU_dwo_name: 0x2130,
      GNU_dwo_id: 0x2131,
      GNU_ranges_base: 0x2132,
      GNU_addr_base: 0x2133,
      GNU_pubnames: 0x2134,
      GNU_pubtypes: 0x2135
    }).permissive

    Encoding = CTypes::Enum.new(uint8, {
      void: 0x0,
      address: 0x1,
      boolean: 0x2,
      complex_float: 0x3,
      float: 0x4,
      signed: 0x5,
      signed_char: 0x6,
      unsigned: 0x7,
      unsigned_char: 0x8,
      imaginary_float: 0x9,
      packed_decimal: 0xa,
      numeric_string: 0xb,
      edited: 0xc,
      signed_fixed: 0xd,
      unsigned_fixed: 0xe,
      decimal_float: 0xf,
      UTF: 0x10,
      UCS: 0x11,
      ASCII: 0x12
    }).permissive

    # Line Number Program `directory_entry_format` and `file_name_entry_format`
    # type field
    EntryFormatType = CTypes::Enum.new(Types::ULEB128, {
      path: 1,
      directory_index: 2,
      timestamp: 3,
      size: 4,
      md5: 5
    }).permissive

    # common unit header used within various debug sections
    class UnitHeader < CTypes::Union
      layout do
        member :unit_length, uint32
        member :dwarf32, struct(unit_length: uint32, version: uint16)
        member :dwarf64, struct(
          _marker: uint32,
          unit_length: uint64,
          version: uint16
        )
      end

      def format
        case unit_length
        when 0xffffffff
          :dwarf64
        when proc { |v| v < 0xfffffff0 }
          :dwarf32
        else
          raise Error, "unsupported format: 0x%08x" % hdr[:unit_length]
        end
      end

      def inner
        # PERF: we're caching this here because the Union type will do a bunch
        # of extra work if we keep accessing the union via different members.
        @inner ||= send(format)
      end

      def version
        inner.version
      end

      def unit_size
        inner.unit_length + inner.class.offsetof(:version)
      end

      def type
        :"#{format}_v#{version}"
      end

      def addr_type
        case format
        when :dwarf64
          CTypes::Helpers.uint64.with_endian(@endian)
        when :dwarf32
          CTypes::Helpers.uint32.with_endian(@endian)
        end
      end
    end

    class AbbreviationDeclaration < CTypes::Struct
      layout do
        attribute :code, Types::ULEB128
        attribute :tag, Tag
        attribute :children, uint8
        attribute :attribute_specifications,
          array(struct({
            name: Attribute,
            form: Form
          }),
            terminator: {name: :zero, form: :zero})
      end

      def inspect
        buf = "<%s\n    [%d] DW_TAG_%s\tDW_CHILDREN_%s\n" %
          [self.class.name, code, tag, (children == 0) ? "no" : "yes"]
        attribute_specifications.each do |spec|
          buf << "            %-15s DW_FORM_%s\n" %
            ["DW_AT_#{spec.name}", spec.form]
        end

        buf.chomp! << ">"
      end

      def children?
        @children == 1
      end
    end

    Operation = CTypes::Enum.new(uint8, {
      addr: 0x03,
      deref: 0x06,
      const1u: 0x08,
      const1s: 0x09,
      const2u: 0x0a,
      const2s: 0x0b,
      const4u: 0x0c,
      const4s: 0x0d,
      const8u: 0x0e,
      const8s: 0x0f,
      constu: 0x10,
      consts: 0x11,
      dup: 0x12,
      drop: 0x13,
      over: 0x14,
      pick: 0x15,
      swap: 0x16,
      rot: 0x17,
      xderef: 0x18,
      abs: 0x19,
      and: 0x1a,
      div: 0x1b,
      minus: 0x1c,
      mod: 0x1d,
      mul: 0x1e,
      neg: 0x1f,
      not: 0x20,
      or: 0x21,
      plus: 0x22,
      plus_uconst: 0x23,
      shl: 0x24,
      shr: 0x25,
      shra: 0x26,
      xor: 0x27,
      bra: 0x28,
      eq: 0x29,
      ge: 0x2a,
      gt: 0x2b,
      le: 0x2c,
      lt: 0x2d,
      ne: 0x2e,
      skip: 0x2f,
      lit0: 0x30,
      lit1: 0x31,
      lit2: 0x32,
      lit3: 0x33,
      lit4: 0x34,
      lit5: 0x35,
      lit6: 0x36,
      lit7: 0x37,
      lit8: 0x38,
      lit9: 0x39,
      lit10: 0x3a,
      lit11: 0x3b,
      lit12: 0x3c,
      lit13: 0x3d,
      lit14: 0x3e,
      lit15: 0x3f,
      lit16: 0x40,
      lit17: 0x41,
      lit18: 0x42,
      lit19: 0x43,
      lit20: 0x44,
      lit21: 0x45,
      lit22: 0x46,
      lit23: 0x47,
      lit24: 0x48,
      lit25: 0x49,
      lit26: 0x4a,
      lit27: 0x4b,
      lit28: 0x4c,
      lit29: 0x4d,
      lit30: 0x4e,
      lit31: 0x4f,
      reg0: 0x50,
      reg1: 0x51,
      reg2: 0x52,
      reg3: 0x53,
      reg4: 0x54,
      reg5: 0x55,
      reg6: 0x56,
      reg7: 0x57,
      reg8: 0x58,
      reg9: 0x59,
      reg10: 0x5a,
      reg11: 0x5b,
      reg12: 0x5c,
      reg13: 0x5d,
      reg14: 0x5e,
      reg15: 0x5f,
      reg16: 0x60,
      reg17: 0x61,
      reg18: 0x62,
      reg19: 0x63,
      reg20: 0x64,
      reg21: 0x65,
      reg22: 0x66,
      reg23: 0x67,
      reg24: 0x68,
      reg25: 0x69,
      reg26: 0x6a,
      reg27: 0x6b,
      reg28: 0x6c,
      reg29: 0x6d,
      reg30: 0x6e,
      reg31: 0x6f,
      breg0: 0x70,
      breg1: 0x71,
      breg2: 0x72,
      breg3: 0x73,
      breg4: 0x74,
      breg5: 0x75,
      breg6: 0x76,
      breg7: 0x77,
      breg8: 0x78,
      breg9: 0x79,
      breg10: 0x7a,
      breg11: 0x7b,
      breg12: 0x7c,
      breg13: 0x7d,
      breg14: 0x7e,
      breg15: 0x7f,
      breg16: 0x80,
      breg17: 0x81,
      breg18: 0x82,
      breg19: 0x83,
      breg20: 0x84,
      breg21: 0x85,
      breg22: 0x86,
      breg23: 0x87,
      breg24: 0x88,
      breg25: 0x89,
      breg26: 0x8a,
      breg27: 0x8b,
      breg28: 0x8c,
      breg29: 0x8d,
      breg30: 0x8e,
      breg31: 0x8f,
      regx: 0x90,
      fbreg: 0x91,
      bregx: 0x92,
      piece: 0x93,
      deref_size: 0x94,
      xderef_size: 0x95,
      nop: 0x96,
      push_object_address: 0x97,
      call2: 0x98,
      call4: 0x99,
      call_ref: 0x9a,
      form_tls_address: 0x9b,
      call_frame_cfa: 0x9c,
      bit_piece: 0x9d,
      implicit_value: 0x9e,
      stack_value: 0x9f,
      implicit_pointer: 0xa0,
      addrx: 0xa1,
      constx: 0xa2,
      entry_value: 0xa3,
      const_type: 0xa4,
      regval_type: 0xa5,
      deref_type: 0xa6,
      xderef_type: 0xa7,
      convert: 0xa8,
      reinterpret: 0xa9,

      GNU_push_tls_address: 0xe0,
      GNU_uninit: 0xf0,
      GNU_encoded_addr: 0xf1,
      GNU_implicit_pointer: 0xf2,
      GNU_entry_value: 0xf3,
      GNU_const_type: 0xf4,
      GNU_regval_type: 0xf5,
      GNU_deref_type: 0xf6,
      GNU_convert: 0xf7,
      GNU_reinterpret: 0xf9,
      GNU_parameter_ref: 0xfa,
      GNU_addr_index: 0xfb,
      GNU_const_index: 0xfc,
      GNU_variable_value: 0xfd
    }).permissive

    # Line Number Program Standard Opcodes
    StandardOpCodes = CTypes::Enum.new(uint8, {
      copy: 1,
      advance_pc: 2,
      advance_line: 3,
      set_file: 4,
      set_column: 5,
      negate_stmt: 6,
      set_basic_block: 7,
      const_add_pc: 8,
      fixed_advance_pc: 9,
      set_prologue_end: 10,
      set_epilogue_begin: 11,
      set_isa: 12
    }).permissive

    # Line Number Program Extended Opcodes
    ExtendedOpCodes = CTypes::Enum.new(uint8, {
      end_sequence: 1,
      set_address: 2,
      define_file: 3,
      set_discriminator: 4,
      lo_user: 128,
      hi_user: 255
    }).permissive
  end
end

require_relative "dwarf/expression"
