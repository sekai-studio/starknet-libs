import { expect } from 'chai';
import { uint256 } from 'starknet';

import { StarknetError, TransactionError } from './signer';

export function strToFelt(str: string): bigint {
  const strB = Buffer.from(str);
  return BigInt(
    strB.reduce((memo, byte) => {
      memo += byte.toString(16);
      return memo;
    }, '0x'),
  );
}

export function feltToStr(felt: bigint): string {
  const newStrB = Buffer.from(felt.toString(16), 'hex');
  return newStrB.toString();
}

export function uint256ToFelt(uint: uint256.Uint256): { low: bigint; high: bigint } {
  return {
    low: BigInt(uint.low.toString()),
    high: BigInt(uint.high.toString()),
  };
}

/**
 * System helpers
 */

export const test = {
  log: (str: string) => console.log('    ' + str),
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  done: (module: any) => module.afterAll(() => process.stdout.write('\u0007')),
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function shouldFail(transaction: Promise<any>) {
  try {
    await transaction;
    expect(true, 'Transaction should fail').to.be.eq(false);
  } catch (e) {
    const err = e as TransactionError;
    expect(err.message).to.be.eq(StarknetError.TRANSACTION_FAILED);
  }
}

export async function tryCatch(fn: () => Promise<void>) {
  try {
    await fn();
  } catch (e) {
    console.error(e);
    expect(true, 'Test failed').to.be.eq(false);
  }
}

export function strToFeltArr(str: string): bigint[] {
  const strArr = str.split('');
  return strArr.map(char => BigInt(Buffer.from(char)[0].toString(10)));
}

export function feltArrToStr(felts: bigint[]): string {
  return felts.reduce((memo, felt) => memo + Buffer.from(felt.toString(16), 'hex').toString(), '');
}
