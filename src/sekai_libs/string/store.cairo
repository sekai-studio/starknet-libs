%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.pow import pow

from sekai_libs.string.manipulation import String_extract_last_char
from sekai_libs.string.constants import (
    SHORT_STRING_MAX_LEN,
    CHAR_SIZE,
    EXTRACT_CHAR_MASK,
    STRING_MAX_LEN,
)

@storage_var
func strings_str(str_id : felt, short_string_index : felt) -> (short_string : felt):
end

@storage_var
func strings_len(str_id : felt) -> (length : felt):
end

#
# Gets a string from storage based on its ID
#
# Parameters:
#   str_id (felt): The ID of the string to return
#
# Returns:
#   str_len (felt): The length of the string
#   str (felt*): The string itself (in char array format)
#
func String_get{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(str_id : felt) -> (str_len : felt, str : felt*):
    alloc_locals
    let (str) = alloc()

    let (str_len) = strings_len.read(str_id)

    if str_len == 0:
        return (str_len, str)
    end

    let (full_ss_len, rem_char_len) = unsigned_div_rem(str_len, SHORT_STRING_MAX_LEN)

    # Initiate loop with # of short strings and the last short string length
    _get_ss_loop(str_id, full_ss_len, rem_char_len, str)
    return (str_len, str)
end

func _get_ss_loop{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(str_id : felt, ss_index : felt, ss_len : felt, str : felt*):
    let (ss_felt) = strings_str.read(str_id, ss_index)
    # Get and separate each character in the short string
    _get_ss_char_loop(ss_felt, ss_index, ss_len, str)

    if ss_index == 0:
        return ()
    end
    # Go to the previous short string
    _get_ss_loop(str_id, ss_index - 1, SHORT_STRING_MAX_LEN, str)
    return ()
end

func _get_ss_char_loop{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(ss_felt : felt, ss_position : felt, char_index : felt, str : felt*):
    # Must be checked at beginning of function here for the case where str_len = x * SHORT_STRING_MAX_LEN
    if char_index == 0:
        return ()
    end

    # Extract last character from short string
    let (ss_rem, char) = String_extract_last_char(ss_felt)

    # Store the character in the correct position, i.e. SHORT_STRING_INDEX * SHORT_STRING_MAX_LEN + INDEX_IN_SHORT_STRING
    assert str[ss_position * SHORT_STRING_MAX_LEN + char_index - 1] = char
    _get_ss_char_loop(ss_rem, ss_position, char_index - 1, str)
    return ()
end

#
# Sets a string in storage based on its ID
#
# Parameters:
#   str_id (felt): The ID of the string to store
#   str_len (felt): The length of the string
#   str (felt*): The string itself (in char array format)
#
func String_set{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    str_id : felt, str_len : felt, str : felt*
):
    alloc_locals
    with_attr error_message("String : exceeding max string length 2^15"):
        assert_le(str_len, STRING_MAX_LEN)
    end
    strings_len.write(str_id, str_len)

    if str_len == 0:
        return ()
    end

    let (full_ss_len, rem_char_len) = unsigned_div_rem(str_len, SHORT_STRING_MAX_LEN)

    # Initiate loop with # of short strings and the last short string length
    _set_ss_loop(str_id, full_ss_len, rem_char_len, str)
    return ()
end

func _set_ss_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    str_id : felt, ss_index : felt, ss_len : felt, str : felt*
):
    # Accumulate all characters in a felt and write it
    _set_ss_char_loop(str_id, 0, ss_index, ss_len, ss_len, str)

    if ss_index == 0:
        return ()
    end
    # Go to the previous short string
    _set_ss_loop(str_id, ss_index - 1, SHORT_STRING_MAX_LEN, str)
    return ()
end

func _set_ss_char_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    str_id : felt,
    ss_felt_acc : felt,
    ss_position : felt,
    ss_len : felt,
    char_index : felt,
    str : felt*,
):
    if char_index == 0:
        strings_str.write(str_id, ss_position, ss_felt_acc)
        return ()
    end

    let (char_offset) = pow(CHAR_SIZE, ss_len - char_index)
    let ss_felt = ss_felt_acc + str[ss_position * SHORT_STRING_MAX_LEN + char_index - 1] * char_offset
    _set_ss_char_loop(str_id, ss_felt, ss_position, ss_len, char_index - 1, str)
    return ()
end

#
# Deletes a string in storage based on its ID
#
# Parameters:
#   str_id (felt): The ID of the string to delete
#
func String_delete{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    str_id : felt
):
    alloc_locals
    let (str_len) = strings_len.read(str_id)

    if str_len == 0:
        return ()
    end

    strings_len.write(str_id, 0)

    let (ss_cells, _) = unsigned_div_rem(str_len, SHORT_STRING_MAX_LEN)
    _delete_loop(str_id, ss_cells)
    return ()
end

func _delete_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    str_id : felt, ss_index : felt
):
    strings_str.write(str_id, ss_index, 0)

    if ss_index == 0:
        return ()
    end

    _delete_loop(str_id, ss_index - 1)
    return ()
end
