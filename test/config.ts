import { config } from 'hardhat';

export default {
  NETWORK: config.mocha.starknetNetwork,
  PRIVATE_KEY_1: '123456789987654321',
  PRIVATE_KEY_2: '987654321123456789',
  L1_ADDRESS_1: BigInt('0x2173e03a3BF1707c487a104f8144d395Eb19f48a'),
  L1_ADDRESS_2: BigInt('0xFa117B40e543f7c5E5b9c0Bf18bCf001a2C0Ed88'),
};
