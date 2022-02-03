import '@shardlabs/starknet-hardhat-plugin';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
  cairo: {
    venv: 'active',
  },
  paths: {
    starknetSources: 'examples',
  },
  networks: {
    starknet_devnet: {
      url: 'http://localhost:5000/',
    },
  },
  mocha: {
    starknetNetwork: 'starknet_devnet',
    // starknetNetwork: 'alpha',
  },
};

export default config;
