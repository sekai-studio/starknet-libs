%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.math_cmp import is_le

const CHAR_MAX_VALUE = 256
const ARRAY_MAX_INDEX = 2 ** 15

@storage_var
func baseURI_str(index : felt) -> (char : felt):
end

@storage_var
func baseURI_len() -> (len : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*):
    write_baseURI(str_len, str)
    return ()
end

@view
func baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    let (str_len, str) = read_baseURI()
    return (str_len, str)
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (q : felt, r : felt):
    let (new_elem, unit) = unsigned_div_rem(token_id, 10)
    return (new_elem, unit)
end

#
# Internals
#

# @view
# func felt_to_string{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#         elem : felt) -> (str_len : felt, str : felt*):
#     let (inverted_str) = alloc()
#     let (str_len) = _felt_to_string_loop(elem, inverted_str, index)

# let (str) = alloc()

# return (str_len, str)
# end

# func _felt_to_string_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#         elem : felt, inverted_str : felt*, index : felt) -> (str_len : felt):
#     assert_le(index, ARRAY_MAX_INDEX)
#     if elem == 0:
#         assert inverted_str[index] = 48  # 48 is utf-8 for "0" in decimal
#         return (index + 1)
#     end

# let (new_elem, unit) = unsigned_div_rem(elem, 10)
#     assert inverted_str[index] = unit + 48  # add 48 to a number in [0, 10) for utf-8 in decimal

# let (is_lower) = is_le(elem, new_elem)
#     if is_lower != 0:
#         return (index + 1)
#     end
#     let (str_len) = _felt_to_string_loop(new_elem, inverted_str, index + 1)
#     return (str_len)
# end

func append{syscall_ptr : felt*, range_check_ptr}(
        base_len : felt, base : felt*, str_len : felt, str : felt*):
    assert_le(base_len + str_len, ARRAY_MAX_INDEX)
    if str_len == 0:
        return ()
    end

    return ()
end

func _append_loop{syscall_ptr : felt*, range_check_ptr}(
        base_len : felt, base : felt*, index : felt, str : felt*):
    if index == 0:
        return ()
    end

    assert base[base_len + index - 1] = str[index - 1]
    _append_loop(base_len, base, index - 1, str)
    return ()
end

#
# Read/Write
#

func write_baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*):
    baseURI_len.write(str_len)
    if str_len == 0:
        return ()
    end

    _write_to_store_loop(str_len, str)
    return ()
end

func _write_to_store_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        index : felt, str : felt*):
    if index == 0:
        return ()
    end

    baseURI_str.write(index - 1, str[index - 1])
    _write_to_store_loop(index - 1, str)
    return ()
end

func read_baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    alloc_locals
    let (str) = alloc()
    let (local str_len) = baseURI_len.read()
    if str_len == 0:
        return (str_len, str)
    end

    _read_store_loop(str_len, str)
    return (str_len, str)
end

func _read_store_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        index : felt, str : felt*):
    if index == 0:
        return ()
    end

    let (char) = baseURI_str.read(index - 1)
    assert str[index - 1] = char
    _read_store_loop(index - 1, str)
    return ()
end
