import { expect } from 'chai';
import { starknet } from 'hardhat';

import Signer from '../lib/signer';
import { feltToStr, shouldFail, strToFelt, test } from '../lib/utils';
import config from './config';

const signer = new Signer(config.PRIVATE_KEY_1);
const other = new Signer(config.PRIVATE_KEY_2);

enum TOKEN {
  MINTED,
  NOT_MINTED_BY_OWNER,
  MINTED_TWICE,
  SAFE_MINTED,
  MINTED_FOR_OTHER,
  SAFE_MINTED_FOR_OTHER,
  TRANSFER,
  SAFE_TRANSFER,
  NOT_OWNED_OR_APPROVED,
  TRANSFER_FROM_OWNER,
  SAFE_TRANSFER_FROM_OWNER,
  APPROVED_TRANSFER,
  SAFE_APPROVED_TRANSFER,
  OPERATOR_TRANSFER,
  SAFE_OPERATOR_TRANSFER,
  OPERATOR_APPROVAL,
  BURNED,
  BURNED_BY_OPERATOR,
  NOT_MINTED,
}

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

    const cardsFactory = await starknet.getContractFactory('token/Cards');
    this.cards = await cardsFactory.deploy({
      name: strToFelt('Sekai'),
      symbol: strToFelt('SKI'),
      owner: signer.addressBigInt,
    });
    test.log('Cards contract deployed\n');
  });

  /**
   * Run tests
   */

  it('should have correct name', async function () {
    const { name } = await this.cards.call('name');
    expect(feltToStr(name)).to.be.eq('Sekai');
  });

  it('should have correct symbol', async function () {
    const { symbol } = await this.cards.call('symbol');
    expect(feltToStr(symbol)).to.be.eq('SKI');
  });

  it('should have correct owner', async function () {
    const { owner } = await this.cards.call('owner');
    expect(owner).to.be.eq(signer.addressBigInt);
  });

  describe('Mint', function () {
    it('should be mintable by owner', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const nonce = await signer.getNonce();

      const tokens = [
        TOKEN.MINTED,
        TOKEN.MINTED_TWICE,
        TOKEN.TRANSFER,
        TOKEN.SAFE_TRANSFER,
        TOKEN.NOT_OWNED_OR_APPROVED,
        TOKEN.TRANSFER_FROM_OWNER,
        TOKEN.SAFE_TRANSFER_FROM_OWNER,
        TOKEN.APPROVED_TRANSFER,
        TOKEN.SAFE_APPROVED_TRANSFER,
        TOKEN.OPERATOR_TRANSFER,
        TOKEN.SAFE_OPERATOR_TRANSFER,
        TOKEN.OPERATOR_APPROVAL,
        TOKEN.BURNED,
        TOKEN.BURNED_BY_OPERATOR,
      ];

      for (let i = 0; i < tokens.length; i++) {
        await signer.sendTransaction(this.cards.address, 'mint', [signer.addressBigInt, tokens[i]], nonce + i);
      }

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance + BigInt(tokens.length));
    });

    it('should have correct token owner', async function () {
      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.MINTED });
      expect(owner).to.be.eq(signer.addressBigInt);
    });

    it('should only be mintable by owner', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await shouldFail(
        other.sendTransaction(this.cards.address, 'mint', [signer.addressBigInt, TOKEN.NOT_MINTED_BY_OWNER]),
      );

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance);
    });

    it('should mint for other account', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'mint', [other.addressBigInt, TOKEN.MINTED_FOR_OTHER]);

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance + 1n);
    });

    it('should not be mintable twice', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });

      await shouldFail(signer.sendTransaction(this.cards.address, 'mint', [signer.addressBigInt, TOKEN.MINTED_TWICE]));

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance);
    });

    it('should be safe mintable by owner', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'safeMint', [signer.addressBigInt, TOKEN.SAFE_MINTED]);

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance + 1n);
    });

    it('should only be safe mintable by owner', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await shouldFail(
        other.sendTransaction(this.cards.address, 'safeMint', [signer.addressBigInt, TOKEN.NOT_MINTED_BY_OWNER]),
      );

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance);
    });

    it('should safe mint for other account', async function () {
      const { balance: currentBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'safeMint', [other.addressBigInt, TOKEN.SAFE_MINTED_FOR_OTHER]);

      const { balance: newBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newBalance).to.be.eq(currentBalance + 1n);
    });
  });

  describe('Transfer', () => {
    it('should transfer owned token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'transfer', [other.addressBigInt, TOKEN.TRANSFER]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.TRANSFER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should only transfer owned token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await shouldFail(
        other.sendTransaction(this.cards.address, 'transfer', [other.addressBigInt, TOKEN.NOT_OWNED_OR_APPROVED]),
      );

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.NOT_OWNED_OR_APPROVED });
      expect(owner).to.be.eq(signer.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance);
      expect(newOtherBalance).to.be.eq(currentOtherBalance);
    });

    it('should safe transfer owned token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'safeTransfer', [other.addressBigInt, TOKEN.SAFE_TRANSFER]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.TRANSFER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should only safe transfer owned token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await shouldFail(
        other.sendTransaction(this.cards.address, 'safeTransfer', [other.addressBigInt, TOKEN.NOT_OWNED_OR_APPROVED]),
      );

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.NOT_OWNED_OR_APPROVED });
      expect(owner).to.be.eq(signer.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance);
      expect(newOtherBalance).to.be.eq(currentOtherBalance);
    });

    it('should transfer from owner of token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'transferFrom', [
        signer.addressBigInt,
        other.addressBigInt,
        TOKEN.TRANSFER_FROM_OWNER,
      ]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.TRANSFER_FROM_OWNER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should not transfer if not approved', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await shouldFail(
        other.sendTransaction(this.cards.address, 'transferFrom', [
          signer.addressBigInt,
          other.addressBigInt,
          TOKEN.NOT_OWNED_OR_APPROVED,
        ]),
      );

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.NOT_OWNED_OR_APPROVED });
      expect(owner).to.be.eq(signer.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance);
      expect(newOtherBalance).to.be.eq(currentOtherBalance);
    });

    it('should safe transfer from owner of token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'safeTransferFrom', [
        signer.addressBigInt,
        other.addressBigInt,
        TOKEN.SAFE_TRANSFER_FROM_OWNER,
      ]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.SAFE_TRANSFER_FROM_OWNER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should not safe transfer if not approved', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await shouldFail(
        other.sendTransaction(this.cards.address, 'safeTransferFrom', [
          signer.addressBigInt,
          other.addressBigInt,
          TOKEN.NOT_OWNED_OR_APPROVED,
        ]),
      );

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.NOT_OWNED_OR_APPROVED });
      expect(owner).to.be.eq(signer.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance);
      expect(newOtherBalance).to.be.eq(currentOtherBalance);
    });

    it('should approve other account', async function () {
      await signer.sendTransaction(this.cards.address, 'approve', [other.addressBigInt, TOKEN.APPROVED_TRANSFER]);

      const { approved_address } = await this.cards.call('getApproved', { token_id: TOKEN.APPROVED_TRANSFER });
      expect(approved_address).to.be.eq(other.addressBigInt);
    });

    it('should not approve if not owner', async function () {
      await shouldFail(
        other.sendTransaction(this.cards.address, 'approve', [signer.addressBigInt, TOKEN.NOT_OWNED_OR_APPROVED]),
      );
    });

    it('should transfer if approved', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await other.sendTransaction(this.cards.address, 'transferFrom', [
        signer.addressBigInt,
        other.addressBigInt,
        TOKEN.APPROVED_TRANSFER,
      ]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.APPROVED_TRANSFER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should safe transfer if approved', async function () {
      await signer.sendTransaction(this.cards.address, 'approve', [other.addressBigInt, TOKEN.SAFE_APPROVED_TRANSFER]);
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      await other.sendTransaction(this.cards.address, 'safeTransferFrom', [
        signer.addressBigInt,
        other.addressBigInt,
        TOKEN.SAFE_APPROVED_TRANSFER,
      ]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.APPROVED_TRANSFER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should revoke approval after transfer', async function () {
      const { approved_address } = await this.cards.call('getApproved', { token_id: TOKEN.APPROVED_TRANSFER });
      expect(approved_address).to.be.eq(0n);
    });

    it('should set as operator', async function () {
      await signer.sendTransaction(this.cards.address, 'setApprovalForAll', [other.addressBigInt, 1]);

      const { approved_for_all } = await this.cards.call('isApprovedForAll', {
        owner: signer.addressBigInt,
        operator: other.addressBigInt,
      });
      expect(approved_for_all).to.be.eq(1n);
    });

    it('should transfer as operator', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      const { approved_address } = await this.cards.call('getApproved', { token_id: TOKEN.OPERATOR_TRANSFER });
      expect(approved_address).to.be.not.eq(other.addressBigInt);

      await other.sendTransaction(this.cards.address, 'transferFrom', [
        signer.addressBigInt,
        other.addressBigInt,
        TOKEN.OPERATOR_TRANSFER,
      ]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.OPERATOR_TRANSFER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should safe transfer as operator', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: currentOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });

      const { approved_address } = await this.cards.call('getApproved', { token_id: TOKEN.OPERATOR_TRANSFER });
      expect(approved_address).to.be.not.eq(other.addressBigInt);

      await other.sendTransaction(this.cards.address, 'safeTransferFrom', [
        signer.addressBigInt,
        other.addressBigInt,
        TOKEN.SAFE_OPERATOR_TRANSFER,
      ]);

      const { owner } = await this.cards.call('ownerOf', { token_id: TOKEN.OPERATOR_TRANSFER });
      expect(owner).to.be.eq(other.addressBigInt);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      const { balance: newOtherBalance } = await this.cards.call('balanceOf', { owner: other.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
      expect(newOtherBalance).to.be.eq(currentOtherBalance + 1n);
    });

    it('should approve as operator', async function () {
      await other.sendTransaction(this.cards.address, 'approve', [signer.addressBigInt, TOKEN.OPERATOR_APPROVAL]);

      const { approved_address } = await this.cards.call('getApproved', { token_id: TOKEN.OPERATOR_APPROVAL });
      expect(approved_address).to.be.eq(signer.addressBigInt);
    });
  });

  describe('Burn', async function () {
    it('should burn owned token', async function () {
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });

      await signer.sendTransaction(this.cards.address, 'burn', [TOKEN.BURNED]);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
    });

    it('should burn approved token', async function () {
      await signer.sendTransaction(this.cards.address, 'setApprovalForAll', [other.addressBigInt, 1]);
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });

      await other.sendTransaction(this.cards.address, 'burn', [TOKEN.BURNED_BY_OPERATOR]);

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance - 1n);
    });

    it('should not burn not owned token', async function () {
      await signer.sendTransaction(this.cards.address, 'setApprovalForAll', [other.addressBigInt, 0]);
      const { balance: currentSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });

      await shouldFail(other.sendTransaction(this.cards.address, 'burn', [TOKEN.NOT_OWNED_OR_APPROVED]));

      const { balance: newSignerBalance } = await this.cards.call('balanceOf', { owner: signer.addressBigInt });
      expect(newSignerBalance).to.be.eq(currentSignerBalance);
    });

    it('should not burn unminted token', async function () {
      await shouldFail(signer.sendTransaction(this.cards.address, 'burn', [TOKEN.NOT_MINTED]));
    });
  });

  test.done(this);
});
