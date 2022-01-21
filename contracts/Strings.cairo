%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.pow import pow
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.registers import get_ap, get_fp_and_pc

const CHAR_MAX_VALUE = 256
const STR_MAX_LEN = 310
const STR_BLOCK_LEN = 31

@storage_var
func baseURI_str(index : felt) -> (char : felt):
end

@storage_var
func baseURI_len() -> (len : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*):
    assert_le(str_len, STR_MAX_LEN)
    baseURI_str.write(0, 15)
    baseURI_len.write(1)
    return ()
end

@view
func baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    alloc_locals
    let (local str_len) = baseURI_len.read()
    let (str) = alloc()
    _read_baseURI(str, 0, str_len)
    return (str_len, str)
end

func _arr_to_str{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*) -> (blocks_len : felt, blocks : felt*):
    alloc_locals
    let (blocks) = alloc()
    local block_len = 0

    if str_len == 0:
        return (0, blocks)
    end

    struct LoopLocals:
        member position : felt
        member in_block_position : felt
        member block_position : felt
        member string_block : felt
    end

    let initial_locs : LoopLocals* = cast(fp - 2, LoopLocals*)
    initial_locs.position = 0; ap++
    initial_locs.in_block_position = 0; ap++
    initial_locs.block_position = 0; ap++
    initial_locs.string_block = 0; ap++

    loop:
    let prev_locs : LoopLocals* = cast(ap - LoopLocals.SIZE, LoopLocals*)
    let locs : LoopLocals* = cast(ap, LoopLocals*)

    create_block:
    # Effectively reset string_block to an empty string on each block
    if prev_locs.in_block_position == 0:
        locs.string_block = str[prev_locs.position]; ap++
    else:
        locs.string_block = prev_locs.string_block * 16 + str[prev_locs.position]; ap++
    end
    locs.position = prev_locs.position + 1; ap++
    # locs.in_block_position = (prev_locs.in_block_position + 1) % STR_BLOCK_LEN; ap++
    locs.in_block_position = (prev_locs.in_block_position + 1); ap++
    if locs.in_block_position == 0:
        jmp write_block
    end
    if (str_len - locs.position) == 0:
        jmp write_block
    end
    locs.block_position = prev_locs.block_position; ap++
    jmp loop

    write_block:
    locs.block_position = prev_locs.block_position + 1; ap++
    blocks[prev_locs.block_position] = locs.string_block
    jmp loop if (str_len - locs.position) != 0

    let (__ap__) = get_ap()
    let (__fp__, _) = get_fp_and_pc()
    return (locs.block_position, blocks)
end

func _read_baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str : felt*, index : felt, len : felt):
    if index == len:
        return ()
    end

    let (char) = baseURI_str.read(index)
    assert [str + index] = char
    _read_baseURI(str, index + 1, len)
    return ()
end

@external
func append{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(str : felt):
    let (curStr) = baseURI_str.read(0)
    let (newStr) = Strings_append(curStr, str)
    baseURI_str.write(0, newStr)
    return ()
end

func Strings_append{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str1 : felt, str2 : felt) -> (str : felt):
    alloc_locals
    let (local shifted_str) = _shift(str1, 1)
    local new_str = shifted_str + str2
    return (new_str)
end

#
# Internals
#

func _shift{range_check_ptr}(str : felt, shift : felt) -> (shifted_str : felt):
    alloc_locals
    let (local shifter) = pow(CHAR_MAX_VALUE, shift)
    local shifted_str = str * shifter
    return (shifted_str)
end
