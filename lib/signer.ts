import { ec } from 'elliptic';
import { StarknetContract } from 'hardhat/types';
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
  private _starkKey: ec.KeyPair;
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

  sign(msgHash: string): ec.Signature {
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
      r: toBigInt(signature.r),
      s: toBigInt(signature.s),
      nonce,
    };
  }

  async sendTransaction(
    to: string,
    selectorName: string,
    calldata: BigIntish[],
    nonce?: BigIntish,
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  ) {
    // TODO type Contract
    const {
      selector,
      r,
      s,
      nonce: nnc,
    } = await this.buildTransaction(this._account, to, selectorName, calldata, nonce);

    return this._account.invoke('execute', { to: toBigInt(to), selector, calldata, nonce: nnc }, [r, s]);
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
