import { expect } from 'chai';
import { uint256 } from 'starknet';

import { StarknetError, TransactionError } from './signer';

/** Short string utils **/

/**
 * Converts a string into a short string numeral
 * (short strings cannot have more than 31 characters)
 * @param {string} str - The string to convert
 * @returns {bigint} - The short string hex value
 */
export function strToShortStringFelt(str: string): bigint {
  const strB = Buffer.from(str);
  return BigInt(
    strB.reduce((memo, byte) => {
      memo += byte.toString(16);
      return memo;
    }, '0x'),
  );
}

/**
 * Converts a short string numeral to a readable string
 * (short strings cannot have more than 31 characters)
 * @param {bigint} felt - The short string hex value
 * @returns {string} - The readable string
 */
export function shortStringFeltToStr(felt: bigint): string {
  const newStrB = Buffer.from(felt.toString(16), 'hex');
  return newStrB.toString();
}

/** Strings utils **/

/**
 * Converts a string into an array of numerical characters in utf-8 encoding
 * @param {string} str - The string to convert
 * @returns {bigint[]} - The string converted as an array of numerical characters
 */
export function strToFeltArr(str: string): bigint[] {
  const strArr = str.split('');
  return strArr.map(char => BigInt(Buffer.from(char)[0].toString(10)));
}

/**
 * Converts an array of utf-8 numerical characters into a readable string
 * @param {bigint[]} felts - The array of numerical characters
 * @returns {string} - The readable string
 */
export function feltArrToStr(felts: bigint[]): string {
  return felts.reduce((memo, felt) => memo + Buffer.from(felt.toString(16), 'hex').toString(), '');
}

/** int256 utils **/

/**
 * Converts an unsigned int256 into readable felt low and high values
 * @param {uint256.Uint256} uint - The uint256 to convert
 * @returns {{ low: bigint; high: bigint }} - The felt values
 */
export function uint256ToFelt(uint: uint256.Uint256): { low: bigint; high: bigint } {
  return {
    low: BigInt(uint.low.toString()),
    high: BigInt(uint.high.toString()),
  };
}

/** System helpers **/

export const test = {
  log: (str: string) => console.log('    ' + str),
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  done: (module: any) => module.afterAll(() => process.stdout.write('\u0007')),
};

/**
 * Expects a StarkNet transaction to fail
 * @param {Promise<any>} transaction - The transaction that should fail
 */
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

/**
 * Logs the error on call fail.
 * Sometimes the error are not correctly displayed. This helper can help debug hard to find errors
 * @param {() => Promise<void>} fn - The function to test
 */
export async function tryCatch(fn: () => Promise<void>) {
  try {
    await fn();
  } catch (e) {
    console.error(e);
    expect(true, 'Test failed').to.be.eq(false);
  }
}
