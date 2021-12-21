import BN from 'bn.js';

import { sign as starkSign, starkEc, verify as starkVerify } from './signature';
import { KeyPair, Signature } from './types';

export { getSelectorFromName } from './signature';

/*
 * Exported Stark Key functions
 */
export const exportPrivateKey = (key: KeyPair) => `0x${key.getPrivate('hex').padStart(64, '0')}`;

export const exportPublicKey = (key: KeyPair) => `0x${key.getPublic(true, 'hex')}`;

export const exportPublicKeyX = (key: KeyPair) => `0x${key.getPublic().getX().toString('hex').padStart(64, '0')}`;

export const loadPrivateKey = (privateKey: string) => starkEc.keyFromPrivate(privateKey.substring(2), 'hex');

export const loadPublicKey = (publicKey: string) => starkEc.keyFromPublic(publicKey.substring(2), 'hex');

/**
 * Signature & Verification
 */
export const signHex = (privateKey: string, message: string) => {
  const key = loadPrivateKey(privateKey);
  const { r, s } = starkSign(key, message);

  return {
    r: `0x${r.toString(16)}`,
    s: `0x${s.toString(16)}`,
  };
};

export const sign = (privateKey: string, message: string) => {
  const key = loadPrivateKey(privateKey);
  return starkSign(key, message);
};

export const verify = (publicKey: string, message: string, signature: Signature) => {
  const key = loadPublicKey(publicKey);
  const sig = {
    r: new BN(signature.r.toString().substring(2), 16),
    s: new BN(signature.s.toString().substring(2), 16),
  };

  return starkVerify(key, message, sig);
};
