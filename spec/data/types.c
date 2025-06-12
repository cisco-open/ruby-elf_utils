/*
 * SPDX-FileCopyrightText: 2025 Cisco
 * SPDX-License-Identifier: MIT
 */

// base types; signed & unsigned
char bt_char;
short bt_short;
int bt_int;
long bt_long;
long long bt_long_long;

unsigned char bt_uchar;
unsigned short bt_ushort;
unsigned int bt_uint;
unsigned long bt_ulong;
unsigned long long bt_ulong_long;

float bt_float;
double bt_double;

// basic arrays
unsigned int array_uint[16];
unsigned char array_uchar[16];
char array_char[16];

// multi-dimensional arrays
char md_array_2[10][20];
char md_array_3[10][20][30];
unsigned int md_array_int[3][4][5];

// struct
struct tlv {
    unsigned int type;
    unsigned int len;
    // flexiable array member/variable length array
    unsigned char value[];
};
struct tlv struct_tlv;

typedef struct tlv tlv;
tlv struct_tlv_typedef;

struct nested {
    unsigned int parent;
    struct {
        int nested_anon_int;
    } anon_struct;
    union {
        int a;
        char b;
    } anon_union;
    struct tlv child;
};
struct nested struct_nested;

struct with_padding {
    short x;
    int y;
} __attribute__((aligned(4)));
struct with_padding struct_with_padding;

struct with_self_pointer {
    struct with_self_pointer *next;
    int id;
};
struct with_self_pointer struct_with_self_pointer;

struct with_bitfield {
    unsigned int a : 1;
    signed int b : 2;
    unsigned char : 0;
    unsigned int c : 1;
};
struct with_bitfield struct_with_bitfield = { .a = 1, .b = -1, .c = 1 };

struct with_unnamed_fields {
    union {
        int a;
    };
};
struct with_unnamed_fields struct_with_unnamed_fields;

/* force tail-padding on this struct to ensure we handle it properly */
struct tail_padded {
    unsigned char a;
}__attribute__((aligned(4)));
struct tail_padded struct_tail_padded[10];

union simple {
    unsigned int id;
    unsigned char buf[32];
};
union simple union_simple;

union complex {
    unsigned int id;
    tlv tlv;
    struct {
        int nested_anon_int;
    } anon_struct;
    union {
        int a;
        char b;
    } anon_union;
};
union complex union_complex;

enum enum_uint32 {
    ZERO  = 0,
    ONE   = 1,
    THREE = 3,
};
enum enum_uint32 enum_value;

void *pointer_void                   = 0;
const void *pointer_const_void       = 0;
volatile void *pointer_volatile_void = 0;

/* this is a struct containing a bunch of int types to verify they map to the
 * correct uint_t types */
struct fund_types {
    char int8;
    short int16;
    int int32;
    long int64;

    signed char sint8;
    signed short sint16;
    signed int sint32;
    signed long sint64;

    unsigned char uint8;
    unsigned short uint16;
    unsigned int uint32;
    unsigned long uint64;

    float flt;
};

/* declare variables */
int var_int;
char var_char_array[10];
char *var_char_pointer       = "blah";
int (*var_func_pointer)(int) = 0;

/* We want to confirm that ElfUtils can find the correct ctype for symbols with
 * the same name.  So create a static variable here with the same name as one
 * in types.c, but a different type */
static char duplicate_variable[32] __attribute__((used)) = "hello world";

/* arbitrary functions */
extern void func_void_void(void);
extern int func_int_void(void);
extern void func_void_int(int id);
extern void func_anon_args(int, long);
extern void func_varargs(char *fmt, ...);

unsigned
fib2(unsigned i)
{
    struct fib_struct {
        int i;
        char buf[];
    } xxx;
    xxx.i = 0;
    if (i == 0) {
        return 0;
    }
    if (i == 1) {
        return 1;
    }
    return fib2(i - 1) + fib2(i - 2);
}
