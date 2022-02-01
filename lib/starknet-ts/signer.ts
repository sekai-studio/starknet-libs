import { StarknetContract } from '@shardlabs/starknet-hardhat-plugin/dist/types';
import { KeyPair, Signature } from 'starknet';
import { getKeyPair, getStarkKey, sign } from 'starknet/dist/utils/ellipticCurve';
import { hashMessage } from 'starknet/dist/utils/hash';
import { BigNumberish } from 'starknet/dist/utils/number';
import { getSelectorFromName } from 'starknet/dist/utils/stark';

export type BigIntish = string | number | bigint;

export enum StarknetError {
  TRANSACTION_FAILED = 'Transaction rejected.',
}

export type TransactionError = {
  message: StarknetError;
};

export default class Signer {
  private _starkKey: KeyPair;
  private _account: StarknetContract;
  public set account(account: StarknetContract) {
    this._account = account;
  }
  public get account() {
    return this._account;
  }
  public get address() {
    return this._account.address;
  }
  public get addressBigInt() {
    return BigInt(this._account.address);
  }

  constructor(privateKey: BigNumberish) {
    this._starkKey = getKeyPair(privateKey);
  }

  getStarkKey(): bigint {
    return BigInt(getStarkKey(this._starkKey));
  }

  sign(msgHash: string): Signature {
    return sign(this._starkKey, msgHash);
  }

  async buildTransaction(
    account: StarknetContract,
    to: string,
    selectorName: string,
    calldata: BigIntish[],
    nonce?: BigIntish,
  ) {
    if (nonce === undefined) {
      const { nonce: nnc } = await account.call('getNonce');
      nonce = nnc;
    }

    const selector = getSelectorFromName(selectorName);
    const calldataStr = calldata.map(e => e.toString());

    const msgHash = hashMessage(account.address, to, selector, calldataStr, nonce.toString());
    const signature = this.sign(msgHash);

    return {
      selector: toBigInt(selector),
      r: toBigInt(signature[0]),
      s: toBigInt(signature[1]),
      nonce,
    };
  }

  async sendTransaction(
    to: string,
    selectorName: string,
    calldata: (BigIntish | BigIntish[])[] = [],
    nonce?: BigIntish,
  ) {
    // Write arrays as [arr.length, arr[0], arr[1], ...]
    const arrayFeltCalldata = calldata.reduce<BigIntish[]>((memo, value) => {
      if (Array.isArray(value)) {
        memo.push(BigInt(value.length));
        memo.push(...value);
      } else {
        memo.push(value);
      }
      return memo;
    }, []);

    // TODO type Contract
    const {
      selector,
      r,
      s,
      nonce: nnc,
    } = await this.buildTransaction(this._account, to, selectorName, arrayFeltCalldata, nonce);

    return this._account.invoke('execute', { to: toBigInt(to), selector, calldata: arrayFeltCalldata, nonce: nnc }, [
      r,
      s,
    ]);
  }

  async getNonce(): Promise<number> {
    const { nonce } = await this._account.call('getNonce');
    return Number(nonce);
  }
}

export function toBigInt(data: BigNumberish | BigIntish): bigint {
  if (typeof data === 'bigint') return data;
  return BigInt(data.toString());
}
