import { expect } from 'chai';

import { StarknetError, TransactionError } from './signer';

export default {
  log: (str: string) => console.log('    ' + str),
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  done: (module: any) => module.afterAll(() => process.stdout.write('\u0007')), // Ring the notification bell on test end
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
