%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check)

# Token name
@storage_var
func _name() -> (name : felt):
end

# Token symbol
@storage_var
func _symbol() -> (symbol : felt):
end

# Mapping from token ID to owner address
@storage_var
func _owners(token_id : felt) -> (owner : felt):
end

# Mapping owner address to token count
@storage_var
func _balances(owner : felt) -> (res : felt):
end

# Mapping from token ID to approved address
@storage_var
func _token_approvals(token_id : felt) -> (approved_address : felt):
end

# Mapping from owner to operator approvals
@storage_var
func _operator_approvals(owner : felt, operator : felt) -> (res : felt):
end

# Initializes the contract by setting a `name` and a `symbol` to the token collection.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt):
    _name.write(name)
    _symbol.write(symbol)
    return ()
end

# Returns the number of tokens in `owner`'s account.
#
# Requirements:
#
# - `owner` cannot be the zero address.
@view
func balance_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt) -> (res : felt):
    if owner == 0:
        # ERC721: balance query for the zero address
        assert 1 = 0
    end

    let (res) = _balances.read(owner=owner)
    return (res)
end

# Returns the owner of the `token_id` token.
#
# Requirements:
#
# - `token_id` must exist.
@view
func owner_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (owner : felt):
    alloc_locals
    let (_owner) = _owners.read(token_id=token_id)
    if _owner == 0:
        # ERC721: owner query for nonexistent token
        assert 1 = 0
    end

    return (_owner)
end

# Returns the token collection name.
@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = _name.read()
    return (name)
end

# Returns the token collection symbol.
@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = _symbol.read()
    return (symbol)
end

# Returns the Uniform Resource Identifier (URI) for `token_id` token.
@view
func token_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (token_uri : felt):
    # ERC721Metadata: URI query for nonexistent token
    _exists(token_id)

    let (base_uri) = _base_uri()
    if base_uri == 0:
        return (0)
    else:
        let uri = base_uri + token_id  # TODO find append function
        return (uri)
    end
end

# Base URI for computing {token_uri}. If set, the resulting URI for each
# token will be the concatenation of the `base_uri` and the `token_id`. Empty
# by default, can be ovrriden in child contracts.
func _base_uri{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        base_uri : felt):
    return (0)
end

# Gives permission to `to` to transfer `token_id` token to another account.
# The approval is cleared when the token is transferred.
#
# Only a single account can be approved at a time, so approving the zero address clears previous approvals.
#
# Requirements
#
# - The caller must own the token or be an approved operator.
# - `token_id` must exist.
@external
func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    alloc_locals
    let (_owner) = _owners.read(token_id=token_id)
    if _owner == 0:
        # ERC721: approval to current owner
        assert 1 = 0
    end

    let (caller) = get_caller_address()
    _is_operator_or_owner(_owner, caller)

    _approve(to, token_id)
    return ()
end

# Returns the account approved for `token_id` token.
#
# Requirements
#
# - `token_id` must exist
@view
func get_approved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt) -> (approved_address : felt):
    # ERC721: approved query for nonexistent token
    _exists(token_id)

    let (approved_address) = _token_approvals.read(token_id=token_id)
    return (approved_address)
end

# Approve or remove `operator` as an operator for the caller.
# Operators can call {transfer_from} or {safe_transfer_from} for any token owned by the caller.
#
# Requirements:
#
# - The `operator` cannot be the caller.
@external
func set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    let (caller) = get_caller_address()
    _set_approval_for_all(caller, operator, approved)
    return ()
end

# Returns if the `operator` is allowed to manage all the assets of `owner`.
@view
func is_approved_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (res : felt):
    let (res) = _operator_approvals.read(owner=owner, operator=operator)
    return (res)
end

# Transfers `token_id` token from `_from` to `to`.
#
# WARNING: Usage of this method is discouraged, use {safe_transfer_from} whenever possible.
#
# Requirements:
#
# - `_from` cannot be the zero address.
# - `to` cannot be the zero address.
# - `token_id` token must be owned by from.
# - If the caller is no `from`, it must be approved to move this token by either {approve} or {set_approve_for_all}.
@external
func transfer_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    let (caller) = get_caller_address()
    _is_approved_or_owner(caller, token_id)

    _transfer(_from, to, token_id)
    return ()
end

# Safely transfers `token_id` token from `_from` to `to`, checking first that contract recipients
# are aware of the ERC721 protocol to prevent tokens from beign forever locked.
#
# Requirements:
#
# - `_from` cannot be the zero address.
# - `to` cannot be the zero address.
# - `token_id` token must exist and be owned by `_from`.
# - If the caller is not `_from`, it must have been allowed to move this token by either {approve} or {set_approval_for_all}.
# - If `to` refers to a smart contract, it must implement {IERC721Receiver-on_ERC721_received}, which is called upon a safe transfer.
@external
func safe_transfer_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    let (caller) = get_caller_address()
    _is_approved_or_owner(caller, token_id)

    _safe_transfer(_from, to, token_id)
    return ()
end

# ## Private functions ###

# Safely transfers `token_id` token from `_from` to `to`, checking first that contract recipients
# are aware of the ERC721 protocol to prevent tokens from being forever locked.
#
# `_data` is additional data, it has no specified format and it is sent in call to `to`. -> /!\ not yet implemented /!\
#
# This internal function is equivalent to {safe_transfer_from}, and can be used yo e.g.
# implement alternative mechanisms to perform token transfers, such as signature-based.
#
# Requirements:
#
# - `_from` cannot be the zero address.
# - `to` cannot be the zero address.
# - `token_id` token must exist and be owned by `_from`.
# - If `to` refers to a smart contract, it must implement {IERC721Receiver-on_erc721_received}, which is called upon a safe transfer.
func _safe_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    _transfer(_from, to, token_id)

    _check_on_erc721_received(_from, to, token_id)
    return ()
end

# Asserts whether `token_id` exists.
#
# Tokens can be managed by their owner or approved accounts via {approve} or {set_approval_for_all}.
#
# Tokens start existing when they are minted (`_mint`),
# and stop existing when they are burned (`_burn`).
func _exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : felt):
    alloc_locals
    let (_owner) = _owners.read(token_id=token_id)

    if _owner == 0:
        assert 1 = 0
    end
    return ()
end

# Asserts whether `token_id` does not exist.
func _not_exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : felt):
    let (_owner) = _owners.read(token_id=token_id)

    assert _owner = 0
    return ()
end

# Asserts wether the `address` is the owner of token `token_id` or an operator.
func _is_operator_or_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, caller : felt):
    if owner == caller:
        return ()
    end

    let (_approved_for_all) = is_approved_for_all(owner, caller)
    if _approved_for_all != 0:
        return ()
    end

    # ERC721: approve caller is not owner nor approved for all
    assert 1 = 0
    return ()
end

# Asserts wether `spender` is allowed to manage `token_id`.
#
# Requirements:
#
# - `token_id` must exist.
func _is_approved_or_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, token_id : felt):
    alloc_locals
    # ERC721: operator query for nonexistent token
    _exists(token_id)

    let (_owner) = _owners.read(token_id)
    if spender == _owner:
        return ()
    end

    let (_approved) = get_approved(token_id)
    if spender == _approved:
        return ()
    end

    let (_approved_for_all) = is_approved_for_all(_owner, spender)
    if _approved_for_all != 0:
        return ()
    end

    # ERC721: transfer caller is not owner nor approved
    assert 1 = 0
    return ()
end

# Safely mints `token_id` and transfers it to `to`.
#
# Requirements:
#
# - `token_id` must not exist.
# - If `to` refers to a smart contract, it must implement {IERC721Receiver-on_ERC721_received}, which is called upon a safe transfer.
func _safe_mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    _mint(to, token_id)

    _check_on_erc721_received(0, to, token_id)
    return ()
end

# Mints `token_id` and transfers it to `to`.
#
# WARNING: Usage of this method is discouraged, use {_safe_mint} whenever possible.
#
# Requirements:
#
# - `token_id` must not exist.
# - `to` cannot be the zero address.
func _mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    if to == 0:
        # ERC721: mint to the zero address
        assert 1 = 0
    end
    # ERC721: token already minted
    _not_exists(token_id)

    _before_token_transfer(0, to, token_id)

    let (to_balance) = _balances.read(owner=to)
    _balances.write(to, to_balance + 1)
    _owners.write(token_id, to)

    _after_token_transfer(0, to, token_id)
    return ()
end

# Destroys `token_id`.
# The approval is cleared when the token is burned.
#
# Requirements:
#
# - `token_id` must exist.
func _burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : felt):
    alloc_locals
    let (_owner) = _owners.read(token_id=token_id)

    _before_token_transfer(_owner, 0, token_id)

    # Clear approvals
    _approve(0, token_id)

    let (owner_balance) = _balances.read(owner=_owner)
    _balances.write(_owner, owner_balance + 1)
    _owners.write(token_id, 0)

    _after_token_transfer(_owner, 0, token_id)
    return ()
end

# Transfers `token_id` from `_from` to `to`.
# As opposed to {transfer_from}, this imposes no restrictions on caller.
#
# Requirements:
#
# - `to` cannot be the zero address.
# - `token_id` token must be owned by `_from`.
func _transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    alloc_locals
    let (_owner) = _owners.read(token_id=token_id)
    # ERC721: transfer from incorrect owner
    assert _owner = _from
    if to == 0:
        # ERC721: trasfer to the zero address
        assert 1 = 0
    end

    _before_token_transfer(_from, to, token_id)

    # Clear approvals from the previous owner
    _approve(0, token_id)

    let (from_balance) = _balances.read(owner=_from)
    _balances.write(_from, from_balance - 1)
    let (to_balance) = _balances.read(owner=to)
    _balances.write(to, to_balance + 1)
    _owners.write(token_id, to)

    _after_token_transfer(_from, to, token_id)
    return ()
end

# Approve `to` to operate on `token_id`.
func _approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, token_id : felt):
    _token_approvals.write(token_id, to)
    return ()
end

# Approve `operator` to operate on all of `owner` tokens.
func _set_approval_for_all{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt, approved : felt):
    if owner == operator:
        # ERC721: approve to caller
        assert 1 = 0
    end

    if approved == 0:
        _operator_approvals.write(owner, operator, 0)
    else:
        _operator_approvals.write(owner, operator, 1)
    end
    return ()
end

# Internal function to ivoke {IERC721Receiver-on_ERC721_received} on a target address.
# The call is not executed if the target address is not a contract.
#
# - `_from` represents the provious owner of the given `token_id`
# - `to` target address that will receive the tokens
# - `token_id` ID of the token to be transferred
# - `_data` optional data to send along with the call -> /!\ Not implemented yet /!\
func _check_on_erc721_received{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    # TODO

    # ERC721: transfer to non ERC721Receiver implementer
    assert 1 = 1
    return ()
end

# Hook that is called before any token transfer. This includes minting
# and burning.
#
# Calling conditions:
#
# - When `_from` and `to` are both non-zero, ``from``'s `token_id` will be
# transferred to `to`.
# - When `from` is zero, `token_id` will be minted for `to`.
# - When `to` is zero, ``from``'s `token_id` will be burned.
# - `from` and `to` are never both zero.
func _before_token_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    return ()
end

# Hook that is called after every token transfer. This includes minting
# and burning.
#
# Calling conditions:
#
# - When `_from` and `to` are both non-zero, ``from``'s `token_id` will be
# transferred to `to`.
# - When `from` is zero, `token_id` will be minted for `to`.
# - When `to` is zero, ``from``'s `token_id` will be burned.
# - `from` and `to` are never both zero.
func _after_token_transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _from : felt, to : felt, token_id : felt):
    return ()
end
