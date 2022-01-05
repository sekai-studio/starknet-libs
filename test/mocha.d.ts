import { StarknetContract } from 'hardhat/types';

declare module 'mocha' {
  export interface Context {
    cards: StarknetContract;
  }
}
