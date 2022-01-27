import { expect } from 'chai';
import { starknet } from 'hardhat';

import Signer from '../lib/starknet-ts/signer';
import config from './config';

const signer = new Signer(config.PRIVATE_KEY_1);

describe('AddressRegistry.cairo', function () {
  this.timeout('5m');

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    const accountFactory = await starknet.getContractFactory('Account');
    const signerAccount = await accountFactory.deploy({ _public_key: signer.getStarkKey() });
    signer.account = signerAccount;

    const addressRegistryFactory = await starknet.getContractFactory('AddressRegistry');
    this.addressRegistry = await addressRegistryFactory.deploy();
  });

  /**
   * Run tests
   */

  it('should the L1 address in the registry', async function () {
    await signer.sendTransaction(this.addressRegistry.address, 'set_L1_address', [config.L1_ADDRESS_1]);

    const { res: l1Address } = await this.addressRegistry.call('get_L1_address', {
      L2_address: signer.addressBigInt,
    });
    expect(l1Address).to.be.equal(config.L1_ADDRESS_1);
  });

  it('should update the L2 address', async function () {
    const { res: l1Address } = await this.addressRegistry.call('get_L1_address', {
      L2_address: signer.addressBigInt,
    });
    expect(l1Address).to.be.equal(config.L1_ADDRESS_1);

    await signer.sendTransaction(this.addressRegistry.address, 'set_L1_address', [config.L1_ADDRESS_2]);

    const { res: l1AddressNew } = await this.addressRegistry.call('get_L1_address', {
      L2_address: signer.addressBigInt,
    });
    expect(l1AddressNew).to.be.equal(config.L1_ADDRESS_2);
  });
});
