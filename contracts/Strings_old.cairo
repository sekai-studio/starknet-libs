%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.pow import pow
from starkware.cairo.common.registers import get_ap, get_fp_and_pc

const CHAR_MAX_VALUE = 256

struct String:
    member data : felt*
    member length : felt
end

@storage_var
func string() -> (res : String):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(str : felt):
    string.write(str)
    return ()
end

@view
func storedString{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        str : felt):
    let (str) = string.read()
    return (str)
end

@view
func length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(str : felt) -> (
        length : felt):
    let (length) = _length(str)
    return (length)
end

@external
func append{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(str : felt):
    let (curStr) = string.read()
    let (newStr) = Strings_append(curStr, str)
    string.write(newStr)
    return ()
end

func Strings_append{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str1 : felt, str2 : felt) -> (str : felt):
    alloc_locals
    let (local shifted_str) = _shift(str1, 1)
    local new_str = shifted_str + str2
    return (new_str)
end

#
# Internals
#

func _shift{range_check_ptr}(str : felt, shift : felt) -> (shifted_str : felt):
    alloc_locals
    let (local shifter) = pow(CHAR_MAX_VALUE, shift)
    local shifted_str = str * shifter
    return (shifted_str)
end

func _length{range_check_ptr}(str : felt) -> (length : felt):
    struct LoopLocals:
        member length : felt
        member str : felt
    end

    if str == 0:
        return (0)
    end

    let initial_locs : LoopLocals* = cast(fp - 2, LoopLocals*)
    initial_locs.length = 0; ap++
    initial_locs.str = str; ap++

    loop:
    let prev_locs : LoopLocals* = cast(ap - LoopLocals.SIZE, LoopLocals*)
    let locs : LoopLocals* = cast(ap, LoopLocals*)
    locs.str = prev_locs.str / CHAR_MAX_VALUE; ap++
    locs.length = prev_locs.length + 1
    let (jump) = is_le(1, locs.str)
    static_assert ap + 1 == locs + LoopLocals.SIZE
    jmp loop if jump != 0; ap++

    # Cap the number of steps.
    let (__ap__) = get_ap()
    let (__fp__, _) = get_fp_and_pc()
    let n_steps = (__ap__ - cast(initial_locs, felt)) / LoopLocals.SIZE - 1
    assert_le(n_steps, 251)
    return (length=locs.length)
end
