%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal

# Token name
@storage_var
func ERC721_name() -> (name : felt):
end

# Token symbol
@storage_var
func ERC721_symbol() -> (symbol : felt):
end

# Mapping from token ID to owner address
@storage_var
func ERC721_owners(token_id : felt) -> (owner : felt):
end

# Mapping owner address to token count
@storage_var
func ERC721_balances(owner : felt) -> (res : felt):
end

# Mapping from token ID to approved address
@storage_var
func ERC721_token_approvals(token_id : felt) -> (approved_address : felt):
end

# Mapping from owner to operator approvals
@storage_var
func ERC721_operator_approvals(owner : felt, operator : felt) -> (res : felt):
end

#
# Constructor
#

# Initializes the contract by setting a `name` and a `symbol` to the token collection.
func ERC721_initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt):
    ERC721_name.write(name)
    ERC721_symbol.write(symbol)
    return ()
end

#
# Getters
#

# Returns the token collection name.
@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721_name.read()
    return (name)
end

# Returns the token collection symbol.
@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721_symbol.read()
    return (symbol)
end

# Returns the number of tokens in `owner`'s account.
#
# Requirements:
#
# - `owner` cannot be the zero address.
@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : felt):
    with_attr error_message("ERC721: balance query for the zero address."):
        assert_not_zero(owner)
    end

    let (balance) = ERC721_balances.read(owner=owner)
    return (balance)
end

# Returns the owner of the `token_id` token.
#
# Requirements:
#
# - `token_id` must exist.
@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (owner : felt):
    alloc_locals
    let (local owner) = ERC721_owners.read(token_id=token_id)
    with_attr error_message("ERC721: owner query for nonexistent token."):
        assert_not_zero(owner)
    end

    return (owner)
end

# Returns the account approved for `token_id` token.
#
# Requirements:
#
# - `token_id` must exist.
@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (approved_address : felt):
    let (approved_address) = ERC721_get_approved(token_id)
    return (approved_address)
end

# Returns if the `operator` is allowed to manage all the assets of `owner`.
@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (approved_for_all : felt):
    let (approved_for_all) = ERC721_operator_approvals.read(owner=owner, operator=operator)
    return (approved_for_all)
end

#
# Internals
#

# Mints `token_id` and transfers it to `recipient`.
#
# WARNING: Usage of this method is discouraged, use {ERC721_safe_mint} whenever possible.
#
# Requirements:
#
# - `token_id` must not exist.
# - `recipient` cannot be the zero address.
func ERC721_mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, token_id : felt):
    with_attr error_message("ERC721: mint to the zero address."):
        assert_not_zero(recipient)
    end
    let (exists) = ERC721_exists(token_id)
    with_attr error_message("ERC721: token already minted."):
        assert exists = 0
    end

    let (recipient_balance) = ERC721_balances.read(owner=recipient)
    ERC721_balances.write(recipient, recipient_balance + 1)
    ERC721_owners.write(token_id, recipient)
    return ()
end

# Safely mints `token_id` and transfers it to `recipient`.
#
# Requirements:
#
# - `token_id` must not exist.
# - If `recipient` refers to a smart contract, it must implement {ERC721_Receiver_on_ERC721_received}, which is called upon a safe transfer.
func ERC721_safe_mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, token_id : felt):
    ERC721_mint(recipient, token_id)

    ERC721_check_on_erc721_received(0, recipient, token_id)
    return ()
end

# Destroys `token_id`.
# The approval is cleared when the token is burned.
#
# Requirements:
#
# - `token_id` must exist.
func ERC721_burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt):
    alloc_locals
    let (exists) = ERC721_exists(token_id)
    with_attr error_message("ERC721: burn to non existent token."):
        assert_not_zero(exists)
    end

    let (local owner) = ERC721_owners.read(token_id=token_id)

    # Clear approvals
    ERC721_clear_approval(token_id)

    let (owner_balance) = ERC721_balances.read(owner=owner)
    ERC721_balances.write(owner, owner_balance - 1)
    ERC721_owners.write(token_id, 0)
    return ()
end

# Transfers `token_id` from `sender` to `recipient`.
#
# WARNING: Usage of this method is discouraged, use {ERC721_safe_transfer} whenever possible.
#
# Requirements:
#
# - `sender` cannot be the zero address.
# - `recipient` cannot be the zero address.
# - `token_id` token must be owned by `sender`.
func ERC721_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    let (owner) = ERC721_owners.read(token_id=token_id)
    with_attr error_message("ERC721: transfer from the zero address."):
        assert_not_zero(sender)
    end
    with_attr error_message("ERC721: transfer to the zero address."):
        assert_not_zero(recipient)
    end
    with_attr error_message("ERC721: transfer from incorrect owner."):
        assert owner = sender
    end

    let (sender_balance) = ERC721_balances.read(owner=sender)
    ERC721_balances.write(sender, sender_balance - 1)

    let (recipient_balance) = ERC721_balances.read(owner=recipient)
    ERC721_balances.write(recipient, recipient_balance + 1)

    ERC721_owners.write(token_id, recipient)
    return ()
end

# Safely transfers `token_id` token from `sender` to `recipient`, checking first that contract recipients
# are aware of the ERC721 protocol to prevent tokens from being forever locked.
#
# `_data` is additional data, it has no specified format and it is sent in call to `to`. -> /!\ not yet implemented /!\
#
# Requirements:
#
# - `sender` cannot be the zero address.
# - `recipient` cannot be the zero address.
# - `token_id` token must exist and be owned by `sender`.
# - If `recipient` refers to a smart contract, it must implement {ERC721_Receiver_on_ERC721_received}, which is called upon a safe transfer.
func ERC721_safe_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    ERC721_transfer(sender, recipient, token_id)

    ERC721_check_on_erc721_received(sender, recipient, token_id)
    return ()
end

# Gives permission to `spender` to transfer `token_id` token to another account.
# The approval is cleared when the token is transferred.
#
# Only a single account can be approved at a time, so approving the zero address clears previous approvals.
#
# Requirements
#
# - `caller` must own the token or be an approved operator.
# - `token_id` must exist.
func ERC721_approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, spender : felt, token_id : felt):
    let (exists) = ERC721_exists(token_id)
    with_attr error_message("ERC721: approval to non existent token."):
        assert_not_zero(exists)
    end
    with_attr error_message("ERC721: approval to current owner."):
        assert_not_equal(caller, spender)
    end

    let (is_operator_or_owner) = ERC721_is_operator_or_owner(caller, token_id)
    with_attr error_message("ERC721: approve caller is not owner nor approved for all."):
        assert_not_zero(is_operator_or_owner)
    end

    ERC721_token_approvals.write(token_id, spender)
    return ()
end

# Gives approval to the zero address, effectively removing all former approvals.
#
# Requirements:
#
# - `token_id` must exist.
func ERC721_clear_approval{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt):
    let (exists) = ERC721_exists(token_id)
    with_attr error_message("ERC721: clear approval to non existent token."):
        assert_not_zero(exists)
    end

    ERC721_token_approvals.write(token_id, 0)
    return ()
end

# Approve or remove `operator` as an operator for the caller.
# Operators can call {ERC721_transfer} for any token owned by the caller.
#
# Requirements:
#
# - The `operator` cannot be the caller.
func ERC721_set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, operator : felt, approved : felt):
    with_attr error_message("ERC721: approve to caller."):
        assert_not_equal(caller, operator)
    end

    ERC721_operator_approvals.write(caller, operator, approved)
    return ()
end

# Returns whether `token_id` exists, i.e. has an owner other than the zero address.
#
# Tokens can be managed by their owner or approved accounts via {ERC721_approve} or {ERC721_set_approval_for_all}.
#
# Tokens start existing when they are minted (`ERC721_mint`),
# and stop existing when they are burned (`ERC721_burn`).
func ERC721_exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (exists : felt):
    let (owner) = ERC721_owners.read(token_id=token_id)

    if owner == 0:
        return (0)
    end

    return (1)
end

# Returns whether the `caller` is the owner of token `token_id` or an operator.
#
# Requirements:
#
# - `token_id` must exist.
func ERC721_is_operator_or_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, token_id : felt) -> (is_operator_or_owner : felt):
    alloc_locals
    with_attr error_message("ERC721: spender query for nonexistent token."):
        ERC721_exists(token_id)
    end

    let (local owner) = ERC721_owners.read(token_id=token_id)
    if owner == caller:
        return (1)
    end

    let (approved_for_all) = ERC721_operator_approvals.read(owner=owner, operator=caller)
    return (approved_for_all)
end

# Returns the account approved for `token_id` token.
#
# Requirements:
#
# - `token_id` must exist.
func ERC721_get_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (approved_address : felt):
    let (exists) = ERC721_exists(token_id)
    with_attr error_message("ERC721: approved query for nonexistent token."):
        assert_not_zero(exists)
    end

    let (approved_address) = ERC721_token_approvals.read(token_id=token_id)
    return (approved_address)
end

# Returns whether `caller` is allowed to manage `token_id`.
#
# Requirements:
#
# - `token_id` must exist.
func ERC721_is_approved_or_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, token_id : felt) -> (is_approved_or_owner : felt):
    let (operator_or_owner) = ERC721_is_operator_or_owner(caller, token_id)
    if operator_or_owner != 0:
        return (1)
    end

    let (approved) = ERC721_get_approved(token_id)
    if caller == approved:
        return (1)
    end

    return (0)
end

# Internal function to invoke {ERC721_Receiver_on_ERC721_received} on a target address.
# The call is not executed if the target address is not a contract.
#
# - `sender` represents the provious owner of the given `token_id`
# - `recipient` target address that will receive the tokens
# - `token_id` ID of the token to be transferred
# - `_data` optional data to send along with the call -> /!\ Not implemented yet /!\
func ERC721_check_on_erc721_received{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, token_id : felt):
    # TODO
    with_attr error_message("ERC721: approved query for nonexistent token."):
        assert_not_zero(1)
    end
    return ()
end
