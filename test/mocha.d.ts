import { StarknetContract } from 'hardhat/types';

declare module 'mocha' {
  export interface Context {
    initializable: StarknetContract;
    nonceInitializable: StarknetContract;
    addressRegistry: StarknetContract;
    erc20: StarknetContract;
  }
}
