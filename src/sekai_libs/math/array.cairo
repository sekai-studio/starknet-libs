%lang starknet

from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict

from sekai_libs.utils.constants import TRUE, FALSE

func concat_arr{range_check_ptr}(arr1_len : felt, arr1 : felt*, arr2_len : felt, arr2 : felt*) -> (
    res_len : felt, res : felt*
):
    alloc_locals
    let (local res : felt*) = alloc()
    memcpy(res, arr1, arr1_len)
    memcpy(res + arr1_len, arr2, arr2_len)
    return (arr1_len + arr2_len, res)
end

func check_arr_uniqueness{range_check_ptr}(arr_len : felt, arr : felt*) -> (is_unique : felt):
    alloc_locals
    let (local dict_start : DictAccess*) = alloc()
    let (local squashed_dict : DictAccess*) = alloc()

    let (dict_end) = _build_dict(arr_len, arr, dict_start)

    let (squashed_dict_end) = squash_dict(dict_start, dict_end, squashed_dict)

    if squashed_dict_end - squashed_dict == arr_len * DictAccess.SIZE:
        return (TRUE)
    else:
        return (FALSE)
    end
end

func _build_dict(arr_len : felt, arr : felt*, dict : DictAccess*) -> (dict : DictAccess*):
    if arr_len == 0:
        return (dict)
    end

    assert dict.key = [arr[arr_len - 1]]
    assert dict.prev_value = 0
    assert dict.new_value = 1

    return _build_dict(arr_len - 1, arr, dict + DictAccess.SIZE)
end
