import { expect } from 'chai';
import { starknet } from 'hardhat';

import Signer, { StarknetError, TransactionError } from '../lib/starknet-ts/signer';
import { shouldFail } from '../lib/starknet-ts/utils';
import config from './config';

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
    const { public_key } = await signer.account.call('getPublicKey');
    expect(public_key).to.be.equal(signer.getStarkKey());
  });

  it('should initialize the Initializable contract', async function () {
    const { res: notInitialized } = await this.initializable.call('initialized');
    expect(notInitialized).to.be.equal(0n);

    await signer.sendTransaction(this.initializable.address, 'initialize', []);

    const { res: initialized } = await this.initializable.call('initialized');
    expect(initialized).to.be.equal(1n);
  });

  it('should not accept lower nonce', async function () {
    const { nonce } = await signer.account.call('getNonce');

    await shouldFail(signer.sendTransaction(this.nonceInitializable.address, 'initialize', [], nonce - 1n));
  });

  it('should not accept higher nonce', async function () {
    const { nonce } = await signer.account.call('getNonce');

    await shouldFail(signer.sendTransaction(this.nonceInitializable.address, 'initialize', [], nonce + 1n));
  });

  it('should accept correct nonce', async function () {
    const { nonce } = await signer.account.call('getNonce');

    await signer.sendTransaction(this.nonceInitializable.address, 'initialize', [], nonce);

    const { res: initialized } = await this.nonceInitializable.call('initialized');
    expect(initialized).to.be.equal(1n);
  });

  it('should secure public key setting with signature', async function () {
    const { public_key } = await signer.account.call('getPublicKey');
    expect(public_key).to.be.equal(signer.getStarkKey());

    await shouldFail(signer.account.invoke('setPublicKey', { new_public_key: other.getStarkKey() }));
  });

  it('should set the public key of the account', async function () {
    const { public_key } = await signer.account.call('getPublicKey');
    expect(public_key).to.be.equal(signer.getStarkKey());

    await signer.sendTransaction(signer.address, 'setPublicKey', [other.getStarkKey()]);

    const { public_key: newPublicKey } = await signer.account.call('getPublicKey');
    expect(newPublicKey).to.be.equal(other.getStarkKey());
  });

  it('should secure public key setting to the owner', async function () {
    const { public_key } = await signer.account.call('getPublicKey');
    expect(public_key).to.be.equal(other.getStarkKey());

    await shouldFail(signer.sendTransaction(signer.address, 'setPublicKey', [signer.getStarkKey()]));
  });
});
