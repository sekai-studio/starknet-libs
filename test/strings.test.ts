import { expect } from 'chai';
import { starknet } from 'hardhat';

import Signer from '../lib/starknet-ts/signer';
import { feltArrToStr, strToFeltArr } from '../lib/starknet-ts/starknet.utils';
import test from '../lib/starknet-ts/test.utils';

const signer = new Signer('123456789987654321');

const CORE_STRING = 'Hello, world! My name is Jag.';
const BASE_URI = 'https://api.sekai.gg/api/v1/assets/';
const BASE_URI_NO_END_SLASH = 'https://api.sekai.gg/api/v1/assets';
const APPENDED_STRING = 'One, Two';

describe('String_Examples.cairo', function () {
  this.timeout('5m');

  /**
   * Deploy all contracts
   */

  this.beforeAll(async function () {
    test.log('Deploying contracts...');
    const accountFactory = await starknet.getContractFactory('Account');
    const signerAccount = await accountFactory.deploy({ _public_key: signer.getStarkKey() });
    signer.account = signerAccount;
    test.log('Signer account deployed');

    const stringsFactory = await starknet.getContractFactory('String_Examples');
    this.strings = await stringsFactory.deploy();
    test.log('String Examples contract deployed\n');
  });

  /**
   * Run tests
   */

  it('should write string in storage and retrieve it', async function () {
    await signer.sendTransaction(this.strings.address, 'writeCoreString', [strToFeltArr(CORE_STRING)]);
    const { str_len, str } = await this.strings.call('readCoreString');
    expect(str_len).to.be.equal(BigInt(CORE_STRING.length));
    expect(feltArrToStr(str)).to.be.equal(CORE_STRING);
  });

  it('should store baseURI and get tokenURI from ID', async function () {
    const tokenId = 123456789n;
    const tokenId_str = tokenId.toString();
    await signer.sendTransaction(this.strings.address, 'setBaseURI', [strToFeltArr(BASE_URI)]);
    const { str_len, str } = await this.strings.call('tokenURI', { token_id: tokenId });
    expect(str_len).to.be.equal(BigInt(BASE_URI.length) + BigInt(tokenId_str));
    expect(feltArrToStr(str)).to.be.equal(BASE_URI + tokenId_str);
  });

  it('should do the same but with no slash at the end of baseURI', async function () {
    const tokenId = 123456789n;
    const tokenId_str = tokenId.toString();
    await signer.sendTransaction(this.strings.address, 'setBaseURI', [strToFeltArr(BASE_URI_NO_END_SLASH)]);
    const { str_len: baseURI_len, str: baseURI } = await this.strings.call('baseURI');
    expect(baseURI_len).to.be.equal(BigInt(BASE_URI_NO_END_SLASH.length));
    expect(feltArrToStr(baseURI)).to.be.equal(BASE_URI_NO_END_SLASH);

    const { str_len, str } = await this.strings.call('tokenURI', { token_id: tokenId });
    expect(str_len).to.be.equal(BigInt(BASE_URI_NO_END_SLASH.length) + 1n + BigInt(tokenId_str));
    expect(feltArrToStr(str)).to.be.equal(BASE_URI_NO_END_SLASH + '/' + tokenId_str);
  });

  it('should append live (no storage change) to a string', async function () {
    const liveString = ', Three, Four.';
    await signer.sendTransaction(this.strings.address, 'writeBaseAppendString', [strToFeltArr(APPENDED_STRING)]);
    const { str_len, str } = await this.strings.call('appendLive', {
      str_len: strToFeltArr(liveString).length,
      str: strToFeltArr(liveString),
    });
    expect(str_len).to.be.equal(BigInt(APPENDED_STRING.length) + BigInt(liveString.length));
    expect(feltArrToStr(str)).to.be.equal(APPENDED_STRING + liveString);
  });

  it('should append to a string in storage', async function () {
    const appendString = ', Three, Four.';
    await signer.sendTransaction(this.strings.address, 'appendInStorage', [strToFeltArr(appendString)]);
    const { str_len, str } = await this.strings.call('getAppendedString');
    expect(str_len).to.be.equal(BigInt(APPENDED_STRING.length) + BigInt(appendString.length));
    expect(feltArrToStr(str)).to.be.equal(APPENDED_STRING + appendString);
  });

  it('should delete a string from storage', async function () {
    await signer.sendTransaction(this.strings.address, 'deleteAppendedString');
    const { str_len, str } = await this.strings.call('getAppendedString');
    expect(str_len).to.be.equal(0);
    expect(feltArrToStr(str)).to.be.equal('');
  });

  test.done(this);
});
