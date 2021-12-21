import BN from 'bn.js';
import { ec } from 'elliptic';

export type KeyPair = ec.KeyPair;

export type Address = BigInt | BN | string;

export type Felt = BigInt;

export interface Signature {
  r: string;
  s: string;
}
