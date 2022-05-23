%lang starknet

from sekai_libs.math.array import check_arr_uniqueness

@view
func checkArrUniqueness{range_check_ptr}(arr_len : felt, arr : felt*):
    check_arr_uniqueness(arr_len, arr)
    return ()
end
