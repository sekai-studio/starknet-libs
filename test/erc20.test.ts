import { expect } from 'chai';
import { starknet } from 'hardhat';
import { uint256 } from 'starknet';

import config from './config';
import Signer from './signer';
import { feltToStr, strToFelt, uint256ToFelt } from './utils';

const signer = new Signer(config.PRIVATE_KEY_1);

describe('ERC20.cairo', function () {
  this.timeout('5m');

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    const accountFactory = await starknet.getContractFactory('Account');
    const signerAccount = await accountFactory.deploy({ _public_key: signer.getStarkKey() });
    signer.account = signerAccount;

    const initial_supply = uint256.bnToUint256(1000);
    const erc20Factory = await starknet.getContractFactory('token/ERC20');
    this.erc20 = await erc20Factory.deploy({
      name: strToFelt('Sekai'),
      symbol: strToFelt('SKI'),
      initial_supply: uint256ToFelt(initial_supply),
      recipient: signer.addressBN,
    });
  });

  /**
   * Run tests
   */

  it('should have correct name', async function () {
    const { name } = await this.erc20.call('name');
    expect(feltToStr(name)).to.be.equal('Sekai');
  });

  it('should have correct symbol', async function () {
    const { symbol } = await this.erc20.call('symbol');
    expect(feltToStr(symbol)).to.be.equal('SKI');
  });
});
