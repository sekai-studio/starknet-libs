%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.math_cmp import is_le

from lib.cairo.Array import concat_arr

const CHAR_MAX_VALUE = 256
const ARRAY_MAX_INDEX = 2 ** 15

#
# Converts a felt to its utf-8 string value
# e.g. felt_to_string(12345) -> (5, [49, 50, 51, 52, 53]) which converts to "12345" in utf-8
#
# Parameters:
#   elem (felt): The felt value to convert
#
# Returns:
#   (felt, felt*): The length and content of the string
#
func felt_to_string{range_check_ptr}(elem : felt) -> (str_len : felt, str : felt*):
    let (str_seed) = alloc()
    return _felt_to_string_loop(elem, str_seed, 0)
end

func _felt_to_string_loop{range_check_ptr}(elem : felt, str_seed : felt*, index : felt) -> (
        str_len : felt, str : felt*):
    alloc_locals
    with_attr error_message("String : exceeding max string length 2^15"):
        assert_le(index, ARRAY_MAX_INDEX)
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
# (felt, felt*): The length and content of the string
#
func path_join{range_check_ptr}(base_len : felt, base : felt*, str_len : felt, str : felt*) -> (
        res_len : felt, res : felt*):
    if base[base_len - 1] == '/':
        return concat_arr(base_len, base, str_len, str)
    end

    assert base[base_len] = '/'  # append the '/' to the first string
    return concat_arr(base_len + 1, base, str_len, str)
end
