import { expect } from 'chai';
import { starknet } from 'hardhat';

import config from './config';
import Signer, { StarknetError, TransactionError } from './signer';

const signer = new Signer(config.PRIVATE_KEY_1);
const other = new Signer(config.PRIVATE_KEY_2);

describe('Account.cairo', function () {
  this.timeout('5m');
  // if (config.NETWORK === 'devnet') {
  //   this.timeout('30s'); // Timeout if >30sec on Local Devnet
  // } else {
  //   this.timeout('5m'); // Timeout if >5min on Alpha Testnet
  // }

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    const accountFactory = await starknet.getContractFactory('Account');
    const signerAccount = await accountFactory.deploy({ _public_key: signer.getStarkKey() });
    signer.account = signerAccount;

    const otherAccount = await accountFactory.deploy({ _public_key: other.getStarkKey() });
    other.account = otherAccount;

    const initializableFactory = await starknet.getContractFactory('Initializable');
    this.initializable = await initializableFactory.deploy();
    this.nonceInitializable = await initializableFactory.deploy();
  });

  /**
   * Run tests
   */

  it('should deploy the Account contract with public key', async function () {
    const { res: publicKey } = await signer.account.call('get_public_key');
    expect(publicKey).to.be.equal(signer.getStarkKey());
  });

  it('should initialize the Initializable contract', async function () {
    const { res: notInitialized } = await this.initializable.call('initialized');
    expect(notInitialized).to.be.equal(0n);

    await signer.sendTransaction(this.initializable.address, 'initialize', []);

    const { res: initialized } = await this.initializable.call('initialized');
    expect(initialized).to.be.equal(1n);
  });

  it('should not accept lower nonce', async function () {
    const { res: currentNonce } = await signer.account.call('get_nonce');

    try {
      await signer.sendTransaction(this.nonceInitializable.address, 'initialize', [], currentNonce - 1n);
      expect(true, 'Transaction should fail').to.be.equal(false);
    } catch (e) {
      const err = e as TransactionError;
      expect(err.message).to.be.equal(StarknetError.TRANSACTION_FAILED);
    }
  });

  it('should not accept higher nonce', async function () {
    const { res: currentNonce } = await signer.account.call('get_nonce');

    try {
      await signer.sendTransaction(this.nonceInitializable.address, 'initialize', [], currentNonce + 1n);
      expect(true, 'Transaction should fail').to.be.equal(false);
    } catch (e) {
      const err = e as TransactionError;
      expect(err.message).to.be.equal(StarknetError.TRANSACTION_FAILED);
    }
  });

  it('should accept correct nonce', async function () {
    const { res: currentNonce } = await signer.account.call('get_nonce');

    await signer.sendTransaction(this.nonceInitializable.address, 'initialize', [], currentNonce);

    const { res: initialized } = await this.nonceInitializable.call('initialized');
    expect(initialized).to.be.equal(1n);
  });

  it('should secure public key setting with signature', async function () {
    const { res: currentPublicKey } = await signer.account.call('get_public_key');
    expect(currentPublicKey).to.be.equal(signer.getStarkKey());

    try {
      await signer.account.invoke('set_public_key', { new_public_key: other.getStarkKey() });
      expect(true, 'Transaction should fail').to.be.equal(false);
    } catch (e) {
      const err = e as TransactionError;
      expect(err.message).to.be.equal(StarknetError.TRANSACTION_FAILED);
    }
  });

  it('should set the public key of the account', async function () {
    const { res: currentPublicKey } = await signer.account.call('get_public_key');
    expect(currentPublicKey).to.be.equal(signer.getStarkKey());

    await signer.sendTransaction(signer.address, 'set_public_key', [other.getStarkKey()]);

    const { res: newPublicKey } = await signer.account.call('get_public_key');
    expect(newPublicKey).to.be.equal(other.getStarkKey());
  });

  it('should secure public key setting to the owner', async function () {
    const { res: currentPublicKey } = await signer.account.call('get_public_key');
    expect(currentPublicKey).to.be.equal(other.getStarkKey());

    try {
      await signer.sendTransaction(signer.address, 'set_public_key', [signer.getStarkKey()]);
      expect(true, 'Transaction should fail').to.be.equal(false);
    } catch (e) {
      const err = e as TransactionError;
      expect(err.message).to.be.equal(StarknetError.TRANSACTION_FAILED);
    }
  });
});
