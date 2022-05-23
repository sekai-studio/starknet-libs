import os
import pytest
import pytest_asyncio

from starkware.starknet.testing.starknet import Starknet

from conftest import LIB_PATH

CONTRACT_FILE = os.path.join(os.path.dirname(__file__), "Array.cairo")


@pytest_asyncio.fixture
async def contract_factory():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(source=CONTRACT_FILE, cairo_path=[LIB_PATH])

    return contract


@pytest.mark.asyncio
async def test_check_array_is_unique(contract_factory):
    array = contract_factory
    arr = [1, 2, 3, 4, 5]
    await array.checkArrUniqueness(arr).call()
    assert True


@pytest.mark.asyncio
async def test_check_array_is_not_unique(contract_factory):
    array = contract_factory
    arr = [1, 1, 3, 3, 4, 4]
    executed_info = await array.checkArrUniqueness(arr).call()
    assert executed_info.result.isUnique == 0
