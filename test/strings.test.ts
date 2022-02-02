import { expect } from 'chai';
import { starknet } from 'hardhat';
import { StarknetContract, StarknetContractFactory } from 'hardhat/types/runtime';

import { feltArrToStr, strToFeltArr } from '../lib/starknet-ts/starknet.utils';
import test, { tryCatch } from '../lib/starknet-ts/test.utils';

const CORE_STRING = 'Hello, world!';
const BASE_URI = 'https://api.sekai.gg/api/v1/assets/';
const BASE_URI_NO_END_SLASH = 'https://api.sekai.gg/api/v1/assets';
const APPENDED_STRING = 'One, Two';

describe('String_Examples.cairo', function () {
  this.timeout('5m');
  let contractFactory: StarknetContractFactory;
  let contractAddress: string;

  before(async function () {
    contractFactory = await starknet.getContractFactory('String_Examples');
  });

  it('should deploy the contract', async function () {
    test.log('Start deployment');
    const contract: StarknetContract = await contractFactory.deploy();
    test.log('Deployed at', contract.address);
    contractAddress = contract.address;
  });

  it('should correctly extract characters', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      const { ss_rem, char } = await contract.call('charExtraction', {
        ss: 127912988138751994336660249421034900698417598180594040243168860296684270963n,
      });
      expect(ss_rem).to.equal(499660109916999977877579099300917580853193742892945469699878360533922933n);
      expect(char).to.equal(115n);
    });
  });

  it('should write string in storage and retrieve it', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      await contract.invoke('writeCoreString', { str: strToFeltArr(CORE_STRING) });
      const { str_len, str } = await contract.call('readCoreString');
      expect(str_len).to.equal(BigInt(CORE_STRING.length));
      expect(feltArrToStr(str)).to.equal(CORE_STRING);
    });
  });

  it('should store baseURI and get tokenURI from ID', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      const tokenId = 123456789n;
      const tokenId_str = tokenId.toString();
      await contract.invoke('setBaseURI', { str: strToFeltArr(BASE_URI) });
      const { str_len, str } = await contract.call('tokenURI', { token_id: tokenId });
      expect(str_len).to.equal(BigInt(BASE_URI.length) + BigInt(tokenId_str.length));
      expect(feltArrToStr(str)).to.equal(BASE_URI + tokenId_str);
    });
  });

  it('should do the same but with no slash at the end of baseURI', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      const tokenId = 123456789n;
      const tokenId_str = tokenId.toString();
      await contract.invoke('setBaseURI', { str: strToFeltArr(BASE_URI_NO_END_SLASH) });
      const { str_len: baseURI_len, str: baseURI } = await contract.call('baseURI');
      expect(baseURI_len).to.equal(BigInt(BASE_URI_NO_END_SLASH.length));
      expect(feltArrToStr(baseURI)).to.equal(BASE_URI_NO_END_SLASH);

      const { str_len, str } = await contract.call('tokenURI', { token_id: tokenId });
      expect(str_len).to.equal(BigInt(BASE_URI_NO_END_SLASH.length) + 1n + BigInt(tokenId_str.length));
      expect(feltArrToStr(str)).to.equal(BASE_URI_NO_END_SLASH + '/' + tokenId_str);
    });
  });

  it('should append live (no storage change) to a string', async function () {
    const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
    const liveString = ', Three, Four.';
    await contract.invoke('writeBaseAppendString', { str: strToFeltArr(APPENDED_STRING) });
    const { str_len, str } = await contract.call('appendLive', {
      str: strToFeltArr(liveString),
    });
    expect(str_len).to.equal(BigInt(APPENDED_STRING.length) + BigInt(liveString.length));
    expect(feltArrToStr(str)).to.equal(APPENDED_STRING + liveString);
  });

  it('should append to a string in storage', async function () {
    const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
    const appendString = ', Three, Four.';
    await contract.invoke('appendInStorage', { str: strToFeltArr(appendString) });
    const { str_len, str } = await contract.call('getAppendedString');
    expect(str_len).to.equal(BigInt(APPENDED_STRING.length) + BigInt(appendString.length));
    expect(feltArrToStr(str)).to.equal(APPENDED_STRING + appendString);
  });

  it('should delete a string from storage', async function () {
    const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
    await contract.invoke('deleteAppendedString');
    const { str_len, str } = await contract.call('getAppendedString');
    expect(str_len).to.equal(0n);
    expect(feltArrToStr(str)).to.equal('');
  });

  test.done(this);
});
