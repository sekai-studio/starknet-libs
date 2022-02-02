%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

from lib.cairo.String import (
    String_get, String_set, String_delete, String_append, String_path_join, String_felt_to_string,
    String_extract_last_char)

const CORE_STRING = 'CORE_STRING'
const BASE_URI = 'BASE_URI'
const APPENDED_STRING = 'APPENDED_STRING'

#
# Getters
#

@view
func charExtraction{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(ss : felt) -> (ss_rem : felt, char : felt):
    let (ss_rem, char) = String_extract_last_char(ss)
    return (ss_rem, char)
end

@view
func readCoreString{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (str_len : felt, str : felt*):
    let (str_len, str) = String_get(CORE_STRING)
    return (str_len, str)
end

@view
func tokenURI{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(token_id : felt) -> (str_len : felt, str : felt*):
    alloc_locals
    let (local base_uri_len, base_uri_str) = String_get(BASE_URI)

    let (token_id_len, token_id_str) = String_felt_to_string(token_id)

    let (uri_len, uri_str) = String_path_join(
        base_uri_len, base_uri_str, token_id_len, token_id_str)
    return (uri_len, uri_str)
end

@view
func baseURI{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (str_len : felt, str : felt*):
    let (str_len, str) = String_get(BASE_URI)
    return (str_len, str)
end

@view
func appendLive{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(str_len : felt, str : felt*) -> (str_len : felt, str : felt*):
    alloc_locals
    let (local base_len, base_str) = String_get(APPENDED_STRING)

    let (appended_len, appended_str) = String_append(base_len, base_str, str_len, str)
    return (appended_len, appended_str)
end

@view
func getAppendedString{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (str_len : felt, str : felt*):
    let (str_len, str) = String_get(APPENDED_STRING)
    return (str_len, str)
end

#
# Externals
#

@external
func writeCoreString{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(str_len : felt, str : felt*):
    String_set(CORE_STRING, str_len, str)
    return ()
end

@external
func setBaseURI{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(str_len : felt, str : felt*):
    String_set(BASE_URI, str_len, str)
    return ()
end

@external
func writeBaseAppendString{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(str_len : felt, str : felt*):
    String_set(APPENDED_STRING, str_len, str)
    return ()
end

@external
func appendInStorage{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(str_len : felt, str : felt*):
    alloc_locals  # required to avoid syscall_ptr and pedersen_ptr revokation
    let (base_len, base_str) = String_get(APPENDED_STRING)

    let (appended_len, appended_str) = String_append(base_len, base_str, str_len, str)

    String_set(APPENDED_STRING, appended_len, appended_str)
    return ()
end

@external
func deleteAppendedString{
        syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}():
    String_delete(APPENDED_STRING)
    return ()
end
