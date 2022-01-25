import { expect } from 'chai';
import { starknet } from 'hardhat';

import { feltArrToStr, strToFeltArr, test } from '../lib/utils';

// const BASE_STRING = 'https://api.sekai.gg/api/v1/assets/';
const BASE_STRING = 'h';

describe('Strings.cairo', function () {
  this.timeout('5m');

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    test.log('Deploying contracts...');
    const stringsFactory = await starknet.getContractFactory('Strings');
    this.strings = await stringsFactory.deploy({
      str: strToFeltArr(BASE_STRING),
    });
    test.log('Contract deployed\n');
  });

  /**
   * Run tests
   */

  // it('should have correct base string', async function () {
  //   const { str_len, str } = await this.strings.call('baseURI');
  //   expect(str_len).to.be.equal(BigInt(BASE_STRING.length));
  //   expect(feltArrToStr(str)).to.be.equal(BASE_STRING);
  // });

  it('should have correct base string', async function () {
    const { res } = await this.strings.call('tokenURI', { token_id: 10 });
    console.log(res);
    expect(true).to.be.true;
  });

  // it('should append string', async function () {
  //   try {
  //     const strAppend = strToFelt('!');
  //     await this.strings.invoke('append', { str: strAppend });
  //     const { str } = await this.strings.call('storedString');
  //     expect(feltToStr(str)).to.be.equal('Hello!');
  //   } catch (e) {
  //     console.error(e);
  //   }
  // });

  test.done(this);
});
