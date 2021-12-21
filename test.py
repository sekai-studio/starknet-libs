from starkware.starknet.public.abi import get_selector_from_name

from tests.utils.Signer import Signer, hash_message

private_key = 0x12345

key = Signer(private_key)
print(hex(key.public_key))

account = 0x021c02dc94c3e6266a182157d2a1b5c136dbfdfeffaa7dbae318fc17261ea1e3
to = 0x0711ec75a95fda334b12d3f45952dd66f82f8d3c164ec93272bbe35f85443a50
selector_name = 'initialize'
calldata = [1]
nonce = 1

selector = get_selector_from_name(selector_name)

msgHash = hash_message(account, to, selector, calldata, nonce)

print(hex(msgHash))

r, s = key.sign(msgHash)
print(hex(r))
print(hex(s))
