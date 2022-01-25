import '@shardlabs/starknet-hardhat-plugin';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
  cairo: {
    // version: '0.7.0', // needs docker active
    venv: 'active',
  },
  networks: {
    devnet: {
      url: 'http://localhost:5000/',
    },
  },
  mocha: {
    starknetNetwork: 'devnet',
    // starknetNetwork: 'alpha',
  },
};

export default config;
