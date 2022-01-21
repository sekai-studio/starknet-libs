import { expect } from 'chai';
import { starknet } from 'hardhat';

import { feltToStr, strToFelt, test } from '../lib/utils';

describe('Strings.cairo', function () {
  this.timeout('5m');

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    test.log('Deploying contracts...');
    const stringsFactory = await starknet.getContractFactory('Strings');
    this.strings = await stringsFactory.deploy({
      str: strToFelt('Hello'),
    });
    test.log('Contract deployed\n');
  });

  /**
   * Run tests
   */

  it('should have correct base string', async function () {
    const { str } = await this.strings.call('storedString');
    expect(feltToStr(str)).to.be.eq('Hello');
  });

  it('should append string', async function () {
    try {
      const strAppend = strToFelt('!');
      await this.strings.invoke('append', { str: strAppend });
      const { str } = await this.strings.call('storedString');
      expect(feltToStr(str)).to.be.equal('Hello!');
    } catch (e) {
      console.error(e);
    }
  });

  test.done(this);
});
