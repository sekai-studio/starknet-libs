%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.registers import get_ap, get_label_location

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
    return read_store()
end

@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (str_len : felt, str : felt*):
    alloc_locals
    let (local id_str_len, id_str) = felt_to_string(token_id)
    let (baseURI_len, baseURI) = read_store()
    let (full_len) = path_join(baseURI_len, baseURI, id_str_len, id_str)

    return (full_len, baseURI)
end

#
# Internals
#

func length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (len : felt):
    return (5)
end

func felt_to_string{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        elem : felt) -> (str_len : felt, str : felt*):
    let (str_seed) = alloc()
    return _felt_to_string_loop(elem, str_seed, 0)
end

func _felt_to_string_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        elem : felt, str_seed : felt*, index : felt) -> (str_len : felt, str : felt*):
    alloc_locals
    assert_le(index, ARRAY_MAX_INDEX)
    let str_arr = cast(str_seed - 1, felt*)

    let (new_elem, unit) = unsigned_div_rem(elem, 10)
    assert str_arr[0] = unit + '0'  # add 48 to a number in [0, 9] for utf-8 in decimal
    if new_elem == 0:
        return (index + 1, str_arr)
    end

    let (is_lower) = is_le(elem, new_elem)
    if is_lower != 0:
        return (index + 1, str_arr)
    end

    return _felt_to_string_loop(new_elem, str_arr, index + 1)
end

# Join to strings together as paths such that path_join("a/b/c", "d/e/f") returns "a/b/c/d/e/f"
func path_join{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        base_len : felt, base : felt*, str_len : felt, str : felt*) -> (full_len : felt):
    # 47 is '/' char in utf-8 decimal
    if base[base_len - 1] == '/':
        append(base_len, base, str_len, str)
        return (base_len + str_len)
    end

    assert base[base_len] = '/'  # append the '/' to the first string
    append(base_len + 1, base, str_len, str)
    return (base_len + str_len + 1)
end

func append{syscall_ptr : felt*, range_check_ptr}(
        base_len : felt, base : felt*, str_len : felt, str : felt*):
    assert_le(base_len + str_len, ARRAY_MAX_INDEX)
    if str_len == 0:
        return ()
    end

    _append_loop(base_len, base, str_len, str)
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

func read_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    alloc_locals
    let (str) = alloc()

    let (str_len) = baseURI_len.read()

    # call length
    # let (ap_val) = get_ap()
    # local str_len : felt = [ap_val]

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
