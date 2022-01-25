%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.registers import get_ap, get_fp_and_pc

const CHAR_MAX_VALUE = 256

@storage_var
func baseURI_str(index : felt) -> (char : felt):
end

@storage_var
func baseURI_len() -> (len : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*):
    write_to_store(str_len, str)
    return ()
end

@view
func baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    let (str_len, str) = read_store()
    return (str_len, str)
end

#
# Internals
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

# func _felt_arr_to_store{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#         str_len : felt, str : felt*):
#     message_received.emit(str_len)
#     baseURI_len.write(str_len)
#     if str_len == 0:
#         return ()
#     end

# let initial_index : felt* = cast(fp, felt*)
#     [initial_index] = str_len - 1; ap++

# loop:
#     let prev_index : felt* = cast(ap - 1, felt*)
#     let index : felt* = cast(ap, felt*)
#     [index] = [prev_index] - 1; ap++
#     baseURI_str.write(index=[index], value=str[[index]])
#     jmp loop if [index] != 0

# return ()
# end

# func _store_to_felt_arr{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
#         str_len : felt, str : felt*):
#     let (str_len) = baseURI_len.read()
#     let (str) = alloc()

# let initial_index : felt* = cast(fp, felt*)
#     [initial_index] = str_len; ap++

# loop:
#     let prev_index : felt* = cast(ap - 1, felt*)
#     let index : felt* = cast(ap, felt*)
#     [index] = [prev_index] - 1; ap++
#     let (char) = baseURI_str.read(index=[index])
#     assert str[[index]] = char
#     jmp loop if [index] != 0

# return (str_len, str)
# end

# func _store_to_felt_arr{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
#         str_len : felt, str : felt*):
#     alloc_locals
#     let (local str_len) = baseURI_len.read()
#     let (str) = alloc()
#     if str_len == 0:
#         return (str_len, str)
#     end

# _write_to_arr_loop(str_len, str)

# return (str_len, str)
# end

# func _write_to_arr_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#         index : felt, str : felt*):
#     let (char) = baseURI_str.read(index - 1)
#     assert str[index - 1] = char

# if (index - 1) == 0:
#         return ()
#     end

# return _write_to_arr_loop(index - 1, str)
# end
