%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero

from contracts.token.ERC721_base import (
    ERC721_initializer, ERC721_mint, ERC721_safe_mint, ERC721_burn, ERC721_is_approved_or_owner,
    ERC721_clear_approval, ERC721_transfer, ERC721_safe_transfer, ERC721_approve,
    ERC721_set_approval_for_all)

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt):
    ERC721_initializer(name, symbol)
    return ()
end

#
# Externals
#

@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    _before_token_transfer(0, to, token_id)

    ERC721_mint(to, token_id)

    _after_token_transfer(0, to, token_id)
    return ()
end

func safeMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    _before_token_transfer(0, to, token_id)

    ERC721_safe_mint(to, token_id)

    _after_token_transfer(0, to, token_id)
    return ()
end

@external
func burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : felt):
    alloc_locals
    let (local caller) = get_caller_address()
    let (approved) = ERC721_is_approved_or_owner(caller, token_id)
    assert_not_zero(approved)  # ERC721: burn caller is not owner nor approved for all

    _before_token_transfer(caller, 0, token_id)

    ERC721_burn(token_id)
    ERC721_clear_approval(token_id)

    _after_token_transfer(caller, 0, token_id)
    return ()
end

@external
func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, token_id : felt):
    alloc_locals
    let (local sender) = get_caller_address()

    _before_token_transfer(sender, recipient, token_id)

    ERC721_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)

    _after_token_transfer(sender, recipient, token_id)
    return ()
end

@external
func safeTransfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, token_id : felt):
    alloc_locals
    let (local sender) = get_caller_address()

    _before_token_transfer(sender, recipient, token_id)

    ERC721_safe_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)

    _after_token_transfer(sender, recipient, token_id)
    return ()
end

@external
func transferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    let (caller) = get_caller_address()
    let (approved) = ERC721_is_approved_or_owner(caller, token_id)
    assert_not_zero(approved)  # ERC721: transferFrom caller is not owner nor approved for all

    _before_token_transfer(sender, recipient, token_id)

    ERC721_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)

    _after_token_transfer(sender, recipient, token_id)
    return ()
end

@external
func safeTransferFrom{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    let (caller) = get_caller_address()
    let (approved) = ERC721_is_approved_or_owner(caller, token_id)
    assert_not_zero(approved)  # ERC721: safeTransferFrom caller is not owner nor approved for all

    _before_token_transfer(sender, recipient, token_id)

    ERC721_safe_transfer(sender, recipient, token_id)
    ERC721_clear_approval(token_id)

    _after_token_transfer(sender, recipient, token_id)
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

#
# Internals
#

# Hook that is called before any token transfer. This includes minting
# and burning.
#
# Calling conditions:
#
# - When `sender` and `recipient` are both non-zero, `sender`'s `token_id` will be
# transferred to `recipient`.
# - When `sender` is zero, `token_id` will be minted for `recipient`.
# - When `recipient` is zero, `sender`'s `token_id` will be burned.
# - `sender` and `recipient` are never both zero.
func _before_token_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    return ()
end

# Hook that is called after every token transfer. This includes minting
# and burning.
#
# Calling conditions:
#
# - When `sender` and `recipient` are both non-zero, `sender`'s `token_id` will be
# transferred to `recipient`.
# - When `sender` is zero, `token_id` will be minted for `recipient`.
# - When `recipient` is zero, `sender`'s `token_id` will be burned.
# - `sender` and `recipient` are never both zero.
func _after_token_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    return ()
end
