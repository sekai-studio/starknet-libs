import { BN } from 'bn.js';
import { getKeyPair, getStarkKey, sign } from 'starknet/dist/utils/ellipticCurve';
import { hashMessage } from 'starknet/dist/utils/hash';
import { getSelectorFromName } from 'starknet/dist/utils/stark';

const config = {
  PUBLIC_KEY: '0x02002f8ffcb446d2a062ef18561eb507b08ea01d52d4c594e90cfca47f075cb952',
  PRIVATE_KEY: '0x12345',
};

const key = getKeyPair(config.PRIVATE_KEY);
console.log(getStarkKey(key));

// Hash message

const account = new BN('021c02dc94c3e6266a182157d2a1b5c136dbfdfeffaa7dbae318fc17261ea1e3', 16);
const to = new BN('0711ec75a95fda334b12d3f45952dd66f82f8d3c164ec93272bbe35f85443a50', 16);
const selectorName = 'initialize';
const calldata: string[] = ['1'];
const nonce = '1';

const selector = getSelectorFromName(selectorName);

const messageHash = hashMessage(account.toString(), to.toString(), selector, calldata, nonce);

console.log(messageHash);

const signature = sign(key, messageHash);
console.log(signature.r.toString('hex'));
console.log(signature.s.toString('hex'));
