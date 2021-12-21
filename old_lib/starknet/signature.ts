import assert from 'assert';
import BN from 'bn.js';
import { curves as eCurves, ec as EllipticCurve } from 'elliptic';
import { keccak } from 'ethereumjs-util';
import hash from 'hash.js';
import { hashMessage } from 'starknet/dist/utils/hash';
import { BigNumberish } from 'starknet/dist/utils/number';

import constantPointsHex from './constant_points';

/*
 Stark Key generation
 */
// Equals 2**251 + 17 * 2**192 + 1.
const prime = new BN('800000000000011000000000000000000000000000000000000000000000001', 16);
// Should equal 252.
const nElementBitsHash = prime.bitLength();
// Equals 2**251. This value limits msgHash and the signature parts.
const maxEcdsaVal = new BN('800000000000000000000000000000000000000000000000000000000000000', 16);
// Equals 2**250 - 1
const mask250 = new BN('3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 16);

const lowPartBits = 248;
// Equals 2**248 - 1
const lowPartMask = new BN('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 16);

// Generate BN of used constants.
const zeroBn = new BN('0', 16);
const oneBn = new BN('1', 16);

export const starkEc = new EllipticCurve(
  new eCurves.PresetCurve({
    type: 'short',
    prime: null,
    p: prime.toString('hex'),
    a: '00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000001',
    b: '06f21413 efbe40de 150e596d 72f7a8c5 609ad26c 15c915c1 f4cdfcb9 9cee9e89',
    n: '08000000 00000010 ffffffff ffffffff b781126d cae7b232 1e66a241 adc64d2f',
    hash: hash.sha256,
    gRed: false,
    g: constantPointsHex[1],
  }),
);

const constantPoints = constantPointsHex.map(coords =>
  starkEc.curve.point(new BN(coords[0], 16), new BN(coords[1], 16)),
);
const shiftPoint = constantPoints[0];
const p0 = constantPoints[2];
const p1 = constantPoints[2 + lowPartBits];
const p2 = constantPoints[2 + nElementBitsHash];
const p3 = constantPoints[2 + nElementBitsHash + lowPartBits];

function starknetKeccak(data: Buffer): BN {
  const hash = keccak(data).toString('hex');
  const hashBn = new BN(hash, 16);
  return hashBn.and(mask250);
}

export function getSelectorFromName(funcName: string): BN {
  return starknetKeccak(Buffer.from(funcName, 'ascii'));
}

/*
 Asserts input is equal to or greater then lowerBound and lower then upperBound.
 Assert message specifies inputName.
 input, lowerBound, and upperBound should be of type BN.
 inputName should be a string.
*/
function assertInRange(input: BN, lowerBound: BN, upperBound: BN, inputName = '') {
  const messageSuffix = inputName === '' ? 'invalid length' : `invalid ${inputName} length`;
  assert(input.gte(lowerBound) && input.lt(upperBound), `Message not signable, ${messageSuffix}.`);
}

// export function computeHashOnElements(data: (string | number | BN)[], hashFunc = pedersen) {}

/*
 Full specification of the hash function can be found here:
   https://starkware.co/starkex/docs/signatures.html#pedersen-hash-function
 shiftPoint was added for technical reasons to make sure the zero point on the elliptic curve does
 not appear during the computation. constantPoints are multiples by powers of 2 of the constant
 points defined in the documentation.
*/
export function pedersenOld(input: (number | string | BN)[]): string {
  let point = shiftPoint;
  for (let i = 0; i < input.length; i += 1) {
    let x = new BN(input[i], 16);
    assert(x.gte(zeroBn) && x.lt(prime), `Invalid input: ${input[i]}`);
    for (let j = 0; j < 252; j += 1) {
      const pt = constantPoints[2 + i * 252 + j];
      assert(!point.getX().eq(pt.getX()));
      if (x.and(oneBn).toNumber() !== 0) {
        point = point.add(pt);
      }
      x = x.shrn(1);
    }
  }
  return point.getX().toString(16);
}

/*
 The function _truncateToN in lib/elliptic/ec/index.js does a shift-right of delta bits,
 if delta is positive, where
   delta = msgHash.byteLength() * 8 - starkEx.n.bitLength().
 This function does the opposite operation so that
   _truncateToN(fixMsgHashLen(msgHash)) == msgHash.
*/
function fixMsgHashLen(msgHash: string | number) {
  // Convert to BN to remove leading zeros.
  const m = new BN(msgHash, 16).toString(16);

  if (m.length <= 62) {
    // In this case, msgHash should not be transformed, as the byteLength() is at most 31,
    // so delta < 0 (see _truncateToN).
    return m;
  }
  assert(m.length === 63);
  // In this case delta will be 4 so we perform a shift-left of 4 bits by adding a zero.
  return `${m}0`;
}

/*
 Signs a message using the provided key.
 privateKey should be an elliptic.keyPair with a valid private key.
 Returns an elliptic.Signature.
*/
export function sign(privateKey: EllipticCurve.KeyPair, msgHash: string): EllipticCurve.Signature {
  const msgHashBN = new BN(msgHash, 16);
  // Verify message hash has valid length.
  assertInRange(msgHashBN, zeroBn, maxEcdsaVal, 'msgHash');
  const msgSignature = privateKey.sign(fixMsgHashLen(msgHash));
  const { r, s } = msgSignature;
  const w = s.invm(starkEc.n);
  // Verify signature has valid length.
  assertInRange(r, oneBn, maxEcdsaVal, 'r');
  assertInRange(s, oneBn, starkEc.n, 's');
  assertInRange(w, oneBn, maxEcdsaVal, 'w');
  return msgSignature;
}

/*
 Verifies a message using the provided key.
 publicKey should be an elliptic.keyPair with a valid public key.
 msgSignature should be an elliptic.Signature.
 Returns a boolean true if the verification succeeds.
*/
export function verify(publicKey: EllipticCurve.KeyPair, msgHash: string, msgSignature: { r: BN; s: BN }): boolean {
  const msgHashBN = new BN(msgHash, 16);
  // Verify message hash has valid length.
  assertInRange(msgHashBN, zeroBn, maxEcdsaVal, 'msgHash');
  const { r, s } = msgSignature;
  const w = s.invm(starkEc.n);
  // Verify signature has valid length.
  assertInRange(r, oneBn, maxEcdsaVal, 'r');
  assertInRange(s, oneBn, starkEc.n, 's');
  assertInRange(w, oneBn, maxEcdsaVal, 'w');
  return publicKey.verify(fixMsgHashLen(msgHash), msgSignature);
}
