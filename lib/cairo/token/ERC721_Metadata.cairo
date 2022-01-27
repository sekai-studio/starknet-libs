%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero

from lib.cairo.token.ERC721_base import ERC721_exists
from lib.cairo.String import felt_to_string, path_join
from lib.cairo.Array import concat_arr

const CHAR_MAX_VALUE = 256
const ARRAY_MAX_INDEX = 2 ** 15

@storage_var
func ERC721_Metadata_base_uri_str(index : felt) -> (char : felt):
end

@storage_var
func ERC721_Metadata_base_uri_len() -> (len : felt):
end

#
# Getters
#

# Returns the base URI.
@view
func baseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    return ERC721_Metadata_read_base_uri()
end

# Returns the token URI.
#
# Requirements:
#
# - `token_id` must exist.
@view
func tokenURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (str_len : felt, str : felt*):
    alloc_locals
    let (exists) = ERC721_exists(token_id)
    assert_not_zero(exists)

    let (local id_str_len, id_str) = felt_to_string(token_id)
    let (base_uri_len, base_uri) = ERC721_Metadata_read_base_uri()

    let (str_len, str) = path_join(base_uri_len, base_uri, id_str_len, id_str)
    return (str_len, str)
end

#
# Read/Write
#

func ERC721_Metadata_write_base_uri{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*):
    ERC721_Metadata_base_uri_len.write(str_len)
    if str_len == 0:
        return ()
    end

    _write_base_uri_loop(str_len, str)
    return ()
end

func _write_base_uri_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        index : felt, str : felt*):
    if index == 0:
        return ()
    end

    ERC721_Metadata_base_uri_str.write(index - 1, str[index - 1])
    _write_base_uri_loop(index - 1, str)
    return ()
end

func ERC721_Metadata_read_base_uri{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str_len : felt, str : felt*):
    alloc_locals
    let (str) = alloc()

    let (str_len) = ERC721_Metadata_base_uri_len.read()

    if str_len == 0:
        return (str_len, str)
    end

    _read_base_uri_loop(str_len, str)
    return (str_len, str)
end

func _read_base_uri_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        index : felt, str : felt*):
    if index == 0:
        return ()
    end

    let (char) = ERC721_Metadata_base_uri_str.read(index - 1)
    assert str[index - 1] = char
    _read_base_uri_loop(index - 1, str)
    return ()
end
