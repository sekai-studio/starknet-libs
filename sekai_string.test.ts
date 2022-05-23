import { expect } from 'chai';
import { starknet } from 'hardhat';
import { StarknetContract, StarknetContractFactory } from 'hardhat/types/runtime';

import { feltArrToStr, strToFeltArr, test, tryCatch } from '../utils';

describe('Sekai StarkNet String Library', function () {
  this.timeout('5m');
  let contractFactory: StarknetContractFactory;
  let contractAddress: string;

  before(async function () {
    contractFactory = await starknet.getContractFactory('String_Examples');
  });

  it('should deploy the contract', async function () {
    const contract: StarknetContract = await contractFactory.deploy();
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
      await contract.invoke('writeCoreString', { str: strToFeltArr('Hello, world!') });
      const { str_len, str } = await contract.call('readCoreString');
      expect(str_len).to.equal(BigInt('Hello, world!'.length));
      expect(feltArrToStr(str)).to.equal('Hello, world!');
    });
  });

  it('should store baseURI and get tokenURI from ID', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      await contract.invoke('setBaseURI', { str: strToFeltArr('https://api.sekai.gg/api/v1/assets/') });
      const { str_len, str } = await contract.call('tokenURI', { token_id: 123456789n });
      expect(str_len).to.equal(BigInt('https://api.sekai.gg/api/v1/assets/'.length) + 9n);
      expect(feltArrToStr(str)).to.equal('https://api.sekai.gg/api/v1/assets/123456789');
    });
  });

  it('should do the same but with no slash at the end of baseURI', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      await contract.invoke('setBaseURI', { str: strToFeltArr('https://api.sekai.gg/api/v1/assets') });
      const { str_len: baseURI_len, str: baseURI } = await contract.call('baseURI');
      expect(baseURI_len).to.equal(BigInt('https://api.sekai.gg/api/v1/assets'.length));
      expect(feltArrToStr(baseURI)).to.equal('https://api.sekai.gg/api/v1/assets');

      const { str_len, str } = await contract.call('tokenURI', { token_id: 987654321n });
      expect(str_len).to.equal(BigInt('https://api.sekai.gg/api/v1/assets'.length) + 1n + 9n);
      expect(feltArrToStr(str)).to.equal('https://api.sekai.gg/api/v1/assets/987654321');
    });
  });

  it('should append live (no storage change) to a string', async function () {
    const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
    await contract.invoke('writeBaseAppendString', { str: strToFeltArr('One, Two') });
    const { str_len, str } = await contract.call('appendLive', {
      str: strToFeltArr(', Three, Four.'),
    });
    expect(str_len).to.equal(BigInt('One, Two'.length) + BigInt(', Three, Four.'.length));
    expect(feltArrToStr(str)).to.equal('One, Two, Three, Four.');
  });

  it('should append to a string in storage', async function () {
    const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
    await contract.invoke('appendInStorage', { str: strToFeltArr(', Three, Four.') });
    const { str_len, str } = await contract.call('getAppendedString');
    expect(str_len).to.equal(BigInt('One, Two'.length) + BigInt(', Three, Four.'.length));
    expect(feltArrToStr(str)).to.equal('One, Two, Three, Four.');
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
