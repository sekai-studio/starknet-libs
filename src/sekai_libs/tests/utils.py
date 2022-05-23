"""Utilities for testing Cairo contracts."""

import math
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.testing.starknet import StarknetContract
from starkware.starknet.business_logic.execution.objects import Event


MAX_FELT = 2**251 + 17 * 2**192 + 1
MAX_UINT256 = (2**128 - 1, 2**128 - 1)
ZERO_ADDRESS = 0
TRUE = 1
FALSE = 0

TRANSACTION_VERSION = 0

#
# Contracts
#


def get_contract_def(path, cairo_path=[]):
    """Returns the contract definition from the contract path"""
    contract_def = compile_starknet_files(
        files=[path], cairo_path=cairo_path, debug_info=True
    )
    return contract_def


def cached_contract(state, deployed):
    """Returns the cached contract"""
    contract = StarknetContract(
        state=state,
        abi=deployed.abi,
        contract_address=deployed.contract_address,
        deploy_execution_info=deployed.deploy_execution_info,
    )
    return contract


#
# Felt manipulation
#


def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def felt_to_str(felt):
    b_felt = felt.to_bytes(31, "big")
    return b_felt.decode()


def uint(a):
    return (a, 0)


def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)


def from_uint(uint):
    """Takes in uint256-ish tuple, returns value."""
    return uint[0] + (uint[1] << 128)


def add_uint(a, b):
    """Returns the sum of two uint256-ish tuples."""
    a = from_uint(a)
    b = from_uint(b)
    c = a + b
    return to_uint(c)


def sub_uint(a, b):
    """Returns the difference of two uint256-ish tuples."""
    a = from_uint(a)
    b = from_uint(b)
    c = a - b
    return to_uint(c)


def mul_uint(a, b):
    """Returns the product of two uint256-ish tuples."""
    a = from_uint(a)
    b = from_uint(b)
    c = a * b
    return to_uint(c)


def div_rem_uint(a, b):
    """Returns the quotient and remainder of two uint256-ish tuples."""
    a = from_uint(a)
    b = from_uint(b)
    c = math.trunc(a / b)
    m = a % b
    return (to_uint(c), to_uint(m))


#
# Assertions
#


async def assert_revert(fun, reverted_with=None):
    try:
        await fun
        assert False
    except StarkException as err:
        _, error = err.args
        if reverted_with is not None:
            assert reverted_with in error["message"]


def assert_event_emitted(tx_exec_info, from_address, name, data):
    assert (
        Event(
            from_address=from_address,
            keys=[get_selector_from_name(name)],
            data=data,
        )
        in tx_exec_info.raw_events
    )
