%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero

from lib.cairo.token.ERC721_base import (
    ERC721_initializer, ERC721_mint, ERC721_safe_mint, ERC721_burn, ERC721_is_approved_or_owner,
    ERC721_clear_approval, ERC721_transfer, ERC721_safe_transfer, ERC721_approve,
    ERC721_set_approval_for_all)
from lib.cairo.token.ERC721_Metadata import ERC721_Metadata_write_base_uri
from lib.cairo.Ownable_base import (
    Ownable_initializer, Ownable_only_owner, Ownable_transfer_ownership)

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt, owner : felt):
    ERC721_initializer(name, symbol)
    Ownable_initializer(owner)
    return ()
end

#
# Externals
#

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    Ownable_only_owner()
    ERC721_mint(to, token_id)
    return ()
end

@external
func safeMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    Ownable_only_owner()
    ERC721_safe_mint(to, token_id)
    return ()
end

@external
func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : felt):
    let (caller) = get_caller_address()
    let (approved) = ERC721_is_approved_or_owner(caller, token_id)
    assert_not_zero(approved)  # ERC721: burn caller is not owner nor approved for all

    ERC721_burn(token_id)
    return ()
end

@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, token_id : felt):
    let (sender) = get_caller_address()

    ERC721_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)
    return ()
end

@external
func safeTransfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, token_id : felt):
    let (sender) = get_caller_address()

    ERC721_safe_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)
    return ()
end

@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    let (caller) = get_caller_address()
    let (approved) = ERC721_is_approved_or_owner(caller, token_id)
    assert_not_zero(approved)  # ERC721: transferFrom caller is not owner nor approved for all

    ERC721_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)
    return ()
end

@external
func safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    let (caller) = get_caller_address()
    let (approved) = ERC721_is_approved_or_owner(caller, token_id)
    assert_not_zero(approved)  # ERC721: safeTransferFrom caller is not owner nor approved for all

    ERC721_safe_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)
    return ()
end

@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, token_id : felt):
    let (caller) = get_caller_address()

    ERC721_approve(caller, spender, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, approval : felt):
    let (caller) = get_caller_address()

    ERC721_set_approval_for_all(caller, spender, approval)
    return ()
end

@external
func setBaseURI{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        str_len : felt, str : felt*):
    Ownable_only_owner()
    ERC721_Metadata_write_base_uri(str_len, str)
    return ()
end
