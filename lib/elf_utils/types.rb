# frozen_string_literal: true

require "ctypes"

# The various types & structures needed to parse the ELF & DWARF formats.
#
# @api private
module ElfUtils::Types
  extend CTypes::Helpers
  extend self

  Elf_Ident = struct({
    ei_magic: string(4),
    ei_class: uint8,
    ei_data: enum(uint8, {none: 0, lsb: 1, msb: 2}),
    ei_version: uint8,
    ei_osabi: uint8,
    ei_abiversion: uint8,
    ei_pad: array(uint8, 7)
  })
  ELFMAGIC = "\x7fELF"
  ELFCLASS32 = 1
  ELFCLASS64 = 2

  # Elf file types
  Elf_Et = enum(uint16, %(none rel exec dyn core)).permissive

  ## Elf Program Header Types
  Elf_Pt = enum(uint32, {
    null: 0, # program header table entry unused
    load: 1, # loadable program segment
    dynamic: 2, # dynamic linking information
    interp: 3, # program interpreter
    note: 4, # auxiliary information
    shlib: 5, # reserved
    phdr: 6, # entry for header table itself
    tls: 7, # thread-local storage segment
    num: 8, # number of defined types
    loos: 0x60000000, # start of os-specific
    gnu_eh_frame: 0x6474e550, # gcc .eh_frame_hdr segment
    gnu_stack: 0x6474e551, # indicates stack executability
    gnu_relro: 0x6474e552, # read-only after relocation
    gnu_property: 0x6474e553, # gnu property
    sunwbss: 0x6ffffffa, # sun specific segment
    sunwstack: 0x6ffffffb # stack segment
  }).permissive

  # Elf file types
  Elf_Pf = enum(uint32, %i[exec write read]).permissive

  # special section header numbers
  SHN_UNDEF = 0 # Undefined section
  SHN_LORESERVE = 0xff00 # Start of reserved indices
  SHN_LOPROC = 0xff00 # Start of processor-specific
  SHN_BEFORE = 0xff00 # Order section before all others (Solaris).
  SHN_AFTER = 0xff01 # Order section after all others (Solaris).
  SHN_HIPROC = 0xff1f # End of processor-specific
  SHN_LOOS = 0xff20 # Start of OS-specific
  SHN_HIOS = 0xff3f # End of OS-specific
  SHN_ABS = 0xfff1 # Associated symbol is absolute
  SHN_COMMON = 0xfff2 # Associated symbol is common
  SHN_XINDEX = 0xffff # Index is in extra table.
  SHN_HIRESERVE = 0xffff # End of reserved indices

  ## Elf Section Header Types
  Elf_Sht = enum(uint32, {
    null: 0, # section header table entry unused
    progbits: 1, # program data
    symtab: 2, # symbol table
    strtab: 3, # string table
    rela: 4, # relocation entries with addends
    hash: 5, # symbol hash table
    dynamic: 6, # dynamic linking information
    note: 7, # notes
    nobits: 8, # program space with no data (bss)
    rel: 9, # relocation entries, no addends
    shlib: 10, # reserved
    dynsym: 11, # dynamic linker symbol table
    init_array: 14, # array of constructors
    fini_array: 15, # array of destructors
    preinit_array: 16, # array of pre-constructors
    group: 17, # section group
    symtab_shndx: 18, # extended section indices
    num: 19, # number of defined types.
    gnu_attributes: 0x6ffffff5, # object attributes.
    gnu_hash: 0x6ffffff6, # gnu-style hash table.
    gnu_liblist: 0x6ffffff7, # prelink library list
    checksum: 0x6ffffff8, # checksum for dso content.
    sunw_move: 0x6ffffffa,
    sunw_comdat: 0x6ffffffb,
    sunw_syminfo: 0x6ffffffc,
    gnu_verdef: 0x6ffffffd, # version definition section.
    gnu_verneed: 0x6ffffffe, # version needs section.
    gnu_versym: 0x6fffffff # version symbol table.
  }).permissive

  # ELF section header flag bits
  Elf_Shf = enum(uint8, {
    write: 0, # writable
    alloc: 1, # occupies memory during execution
    execinstr: 2, # executable
    merge: 4, # might be merged
    strings: 5, # contains nul-terminated strings
    info_link: 6, # `sh_info' contains sht index
    link_order: 7, # preserve order after combining
    os_nonconforming: 8, # non-standard os specific handling required
    group: 9, # section is member of a group.
    tls: 10, # section hold thread-local data.
    compressed: 11, # section with compressed data.
    gnu_retain: 21,  # not to be gced by linker.
    ordered: 30, # special ordering requirement (solaris).
    exclude: 31 # section is excluded unless referenced or allocated (solaris).
  }).permissive

  ## Elf Symbol Types
  Elf_Stt = [ # standard:disable Naming/ConstantName
    :notype,
    :object,
    :func,
    :section,
    :file,
    :common,
    :tls,
    :unused_7,
    :unused_8,
    :unused_9,
    :os_10,
    :os_11,
    :os_12,
    :proc_13,
    :proc_14,
    :proc_15
  ]

  Elf32_Addr = uint32
  Elf32_Chdr = struct({ch_type: uint32, ch_size: uint32, ch_addralign: uint32})
  Elf32_Conflict = uint32
  Elf32_Dyn = struct({d_tag: int32, d_un: union({d_val: uint32, d_ptr: uint32})})
  Elf32_Ehdr = struct({e_ident: Elf_Ident,
     e_type: Elf_Et,
     e_machine: uint16,
     e_version: uint32,
     e_entry: uint32,
     e_phoff: uint32,
     e_shoff: uint32,
     e_flags: uint32,
     e_ehsize: uint16,
     e_phentsize: uint16,
     e_phnum: uint16,
     e_shentsize: uint16,
     e_shnum: uint16,
     e_shstrndx: uint16})
  Elf32_Half = uint16
  Elf32_Lib = struct({l_name: uint32,
     l_time_stamp: uint32,
     l_checksum: uint32,
     l_version: uint32,
     l_flags: uint32})
  Elf32_Move = struct({m_value: uint64,
     m_info: uint32,
     m_poffset: uint32,
     m_repeat: uint16,
     m_stride: uint16})
  Elf32_Nhdr = struct({n_namesz: uint32, n_descsz: uint32, n_type: uint32})
  Elf32_Off = uint32
  Elf32_Phdr = struct({p_type: Elf_Pt,
     p_offset: uint32,
     p_vaddr: uint32,
     p_paddr: uint32,
     p_filesz: uint32,
     p_memsz: uint32,
     p_flags: bitmap(uint32, Elf_Pf),
     p_align: uint32})
  Elf32_RegInfo = struct({ri_gprmask: uint32,
     ri_cprmask: array(uint32, 4),
     ri_gp_value: int32})
  Elf32_Rel = struct({r_offset: uint32, r_info: uint32})
  Elf32_Rela = struct({r_offset: uint32, r_info: uint32, r_addend: int32})
  Elf32_Section = uint16
  Elf32_Shdr = struct({sh_name: uint32,
     sh_type: Elf_Sht,
     sh_flags: bitmap(uint32, Elf_Shf),
     sh_addr: uint32,
     sh_offset: uint32,
     sh_size: uint32,
     sh_link: uint32,
     sh_info: uint32,
     sh_addralign: uint32,
     sh_entsize: uint32})
  Elf32_Sword = int32
  Elf32_Sxword = int64
  Elf32_Sym = struct({st_name: uint32,
     st_value: uint32,
     st_size: uint32,
     st_info: uint8,
     st_other: uint8,
     st_shndx: uint16})
  Elf32_Syminfo = struct({si_boundto: uint16, si_flags: uint16})
  Elf32_Verdaux = struct({vda_name: uint32, vda_next: uint32})
  Elf32_Verdef = struct({vd_version: uint16,
     vd_flags: uint16,
     vd_ndx: uint16,
     vd_cnt: uint16,
     vd_hash: uint32,
     vd_aux: uint32,
     vd_next: uint32})
  Elf32_Vernaux = struct({vna_hash: uint32,
     vna_flags: uint16,
     vna_other: uint16,
     vna_name: uint32,
     vna_next: uint32})
  Elf32_Verneed = struct({vn_version: uint16,
     vn_cnt: uint16,
     vn_file: uint32,
     vn_aux: uint32,
     vn_next: uint32})
  Elf32_Versym = uint16
  Elf32_Word = uint32
  Elf32_Xword = uint64
  Elf32_auxv_t = struct({a_type: uint32, a_un: union({a_val: uint32})})
  Elf32_gptab = union({gt_thing: struct({gt_g_value: uint32, gt_bytes: uint32}),
     gt_header: struct({gt_current_g_value: uint32, gt_unused: uint32}),
     gt_entry: struct({gt_g_value: uint32, gt_bytes: uint32})})
  Elf64_Addr = uint64
  Elf64_Chdr = struct({ch_type: uint32,
     ch_reserved: uint32,
     ch_size: uint64,
     ch_addralign: uint64})
  Elf64_Dyn = struct({d_tag: int64, d_un: union({d_val: uint64, d_ptr: uint64})})
  Elf64_Ehdr = struct({e_ident: Elf_Ident,
     e_type: Elf_Et,
     e_machine: uint16,
     e_version: uint32,
     e_entry: uint64,
     e_phoff: uint64,
     e_shoff: uint64,
     e_flags: uint32,
     e_ehsize: uint16,
     e_phentsize: uint16,
     e_phnum: uint16,
     e_shentsize: uint16,
     e_shnum: uint16,
     e_shstrndx: uint16})
  Elf64_Half = uint16
  Elf64_Lib = struct({l_name: uint32,
     l_time_stamp: uint32,
     l_checksum: uint32,
     l_version: uint32,
     l_flags: uint32})
  Elf64_Move = struct({m_value: uint64,
     m_info: uint64,
     m_poffset: uint64,
     m_repeat: uint16,
     m_stride: uint16})
  Elf64_Nhdr = struct({n_namesz: uint32, n_descsz: uint32, n_type: uint32})
  Elf64_Off = uint64
  Elf64_Phdr = struct({p_type: Elf_Pt,
     p_flags: bitmap(uint32, Elf_Pf),
     p_offset: uint64,
     p_vaddr: uint64,
     p_paddr: uint64,
     p_filesz: uint64,
     p_memsz: uint64,
     p_align: uint64})
  Elf64_Rel = struct({r_offset: uint64, r_info: uint64})
  Elf64_Rela = struct({r_offset: uint64, r_info: uint64, r_addend: int64})
  Elf64_Section = uint16
  Elf64_Shdr = struct({sh_name: uint32,
     sh_type: Elf_Sht,
     sh_flags: bitmap(uint64, Elf_Shf),
     sh_addr: uint64,
     sh_offset: uint64,
     sh_size: uint64,
     sh_link: uint32,
     sh_info: uint32,
     sh_addralign: uint64,
     sh_entsize: uint64})
  Elf64_Sword = int32
  Elf64_Sxword = int64
  Elf64_Sym = struct({st_name: uint32,
     st_info: uint8,
     st_other: uint8,
     st_shndx: uint16,
     st_value: uint64,
     st_size: uint64})
  Elf64_Syminfo = struct({si_boundto: uint16, si_flags: uint16})
  Elf64_Verdaux = struct({vda_name: uint32, vda_next: uint32})
  Elf64_Verdef = struct({vd_version: uint16,
     vd_flags: uint16,
     vd_ndx: uint16,
     vd_cnt: uint16,
     vd_hash: uint32,
     vd_aux: uint32,
     vd_next: uint32})
  Elf64_Vernaux = struct({vna_hash: uint32,
     vna_flags: uint16,
     vna_other: uint16,
     vna_name: uint32,
     vna_next: uint32})
  Elf64_Verneed = struct({vn_version: uint16,
     vn_cnt: uint16,
     vn_file: uint32,
     vn_aux: uint32,
     vn_next: uint32})
  Elf64_Versym = uint16
  Elf64_Word = uint32
  Elf64_Xword = uint64
  Elf64_auxv_t = struct({a_type: uint64, a_un: union({a_val: uint64})})
  Elf_MIPS_ABIFlags_v0 = struct({version: uint16,
     isa_level: uint8,
     isa_rev: uint8,
     gpr_size: uint8,
     cpr1_size: uint8,
     cpr2_size: uint8,
     fp_abi: uint8,
     isa_ext: uint32,
     ases: uint32,
     flags1: uint32,
     flags2: uint32})
  Elf_Options = struct({kind: uint8, size: uint8, section: uint16, info: uint32})
  Elf_Options_Hw = struct({hwp_flags1: uint32, hwp_flags2: uint32})
end

require_relative "types/uleb128"
require_relative "types/sleb128"
require_relative "types/dwarf"
require_relative "types/dwarf32"
require_relative "types/dwarf64"
