%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_le, assert_250_bit
from starkware.cairo.common.math_cmp import is_le

from sekai_libs.math.array import concat_arr
from sekai_libs.string.constants import (
    SHORT_STRING_MAX_LEN,
    CHAR_SIZE,
    EXTRACT_CHAR_MASK,
    STRING_MAX_LEN,
)

#
# Converts a felt to its utf-8 string value
# e.g. 12345 -> 0x3132333435 -> (5, [49, 50, 51, 52, 53]) -> "12345"
#
# Parameters:
#   elem (felt): The felt value to convert
#
# Returns:
#   str_len (felt): The length of the string
#   str (felt*): The string itself (in char array format)
#
func String_felt_to_string{range_check_ptr}(elem : felt) -> (str_len : felt, str : felt*):
    let (str_seed) = alloc()
    return _felt_to_string_loop(elem, str_seed, 0)
end

func _felt_to_string_loop{range_check_ptr}(elem : felt, str_seed : felt*, index : felt) -> (
    str_len : felt, str : felt*
):
    alloc_locals
    with_attr error_message("String : exceeding max string length 2^15"):
        assert_le(index, STRING_MAX_LEN)
    end
    let str_arr = cast(str_seed - 1, felt*)

    let (new_elem, unit) = unsigned_div_rem(elem, 10)
    assert str_arr[0] = unit + '0'  # add '0' (= 48) to a number in range [0, 9] for utf-8 character code
    if new_elem == 0:
        return (index + 1, str_arr)
    end

    let (is_lower) = is_le(elem, new_elem)
    if is_lower != 0:
        return (index + 1, str_arr)
    end

    return _felt_to_string_loop(new_elem, str_arr, index + 1)
end

#
# Joins to strings together and adding a '/' in between if needed
# e.g. path_join("sekai.gg", "assets") -> "sekai.gg/assets"
#
# Parameters:
#   base_len (felt): The first string's length
#   base (felt*): The first string
#   str_len (felt): The second string's length
#   str (felt*): The second string
#
# Returns:
#   str_len (felt): The length of the string
#   str (felt*): The string itself (in char array format)
#
func String_path_join{range_check_ptr}(
    base_len : felt, base : felt*, str_len : felt, str : felt*
) -> (res_len : felt, res : felt*):
    if base[base_len - 1] == '/':
        return concat_arr(base_len, base, str_len, str)
    end

    assert base[base_len] = '/'  # append the '/' to the first string
    return concat_arr(base_len + 1, base, str_len, str)
end

#
# Appends two strings together
# ** Wrapper of Array.concat_arr **
#
# Parameters:
#   base_len (felt): The first string's length
#   base (felt*): The first string
#   str_len (felt): The second string's length
#   str (felt*): The second string
#
# Returns:
#   str_len (felt): The length of the string
#   str (felt*): The string itself (in char array format)
#
func String_append{range_check_ptr}(base_len : felt, base : felt*, str_len : felt, str : felt*) -> (
    res_len : felt, res : felt*
):
    return concat_arr(base_len, base, str_len, str)
end

#
# Extracts the last character from a short string and returns the characters before as a short string
# Manages felt up to 2**248 - 1 (instead of unsigned_div_rem which is limited by rc_bound)
# _On the down side it requires BitwiseBuiltin for the whole call chain_
#
# Parameters:
#   ss (felt): The shortstring
#
# Returns:
#   ss_rem (felt): All the characters before as a short string
#   char (felt): The last character
#
func String_extract_last_char{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(ss : felt) -> (
    ss_rem : felt, char : felt
):
    with_attr error_message("String : exceeding max short string value 2^248 - 1"):
        # We should assert 248 bit here but for now it's "enough" for starters
        # assert_le is limited by RANGE_CHECK_BOUND
        assert_250_bit(ss)
    end

    let (masked_value) = bitwise_and(ss, EXTRACT_CHAR_MASK)
    let ss_rem = masked_value / CHAR_SIZE
    let char = ss - masked_value

    return (ss_rem, char)
end
