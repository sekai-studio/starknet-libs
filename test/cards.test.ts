import { expect } from 'chai';
import { starknet } from 'hardhat';

import Signer from '../lib/signer';
import { feltToStr, strToFelt, test } from '../lib/utils';
import config from './config';

const signer = new Signer(config.PRIVATE_KEY_1);
const other = new Signer(config.PRIVATE_KEY_2);

describe('ERC721 - Cards.cairo', function () {
  this.timeout('5m');

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    test.log('Deploying contracts...');
    const accountFactory = await starknet.getContractFactory('Account');
    const signerAccount = await accountFactory.deploy({ _public_key: signer.getStarkKey() });
    signer.account = signerAccount;
    test.log('Signer account 1 deployed');

    const otherAccount = await accountFactory.deploy({ _public_key: other.getStarkKey() });
    other.account = otherAccount;
    test.log('Signer account 2 deployed');

    const cardsFactory = await starknet.getContractFactory('token/ERC721');
    this.cards = await cardsFactory.deploy({
      name: strToFelt('Sekai'),
      symbol: strToFelt('SKI'),
    });
    test.log('Cards contract deployed\n');
  });

  /**
   * Run tests
   */

  it('should have correct name', async function () {
    const { name } = await this.cards.call('name');
    expect(feltToStr(name)).to.be.equal('Sekai');
  });

  it('should have correct symbol', async function () {
    const { symbol } = await this.cards.call('symbol');
    expect(feltToStr(symbol)).to.be.equal('SKI');
  });

  test.done(this);
});
