%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func Ownable_owner() -> (owner : felt):
end

func Ownable_initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt):
    Ownable_owner.write(owner)
    return ()
end

#
# Getters
#

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    let (owner) = Ownable_get_owner()
    return (owner)
end

#
# Internals
#

func Ownable_only_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (owner) = Ownable_owner.read()
    let (caller) = get_caller_address()
    assert owner = caller
    return ()
end

func Ownable_get_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        owner : felt):
    let (owner) = Ownable_owner.read()
    return (owner)
end

func Ownable_transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        new_owner : felt) -> (new_owner : felt):
    Ownable_only_owner()
    Ownable_owner.write(new_owner)
    return (new_owner)
end
