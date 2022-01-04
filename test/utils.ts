import { uint256 } from 'starknet';

export function strToFelt(str: string): bigint {
  const strB = Buffer.from(str);
  return BigInt(
    strB.reduce((memo, byte) => {
      memo += byte.toString(16);
      return memo;
    }, '0x'),
  );
}

export function feltToStr(felt: bigint): string {
  const newStrB = Buffer.from(felt.toString(16), 'hex');
  return newStrB.toString();
}

export function uint256ToFelt(uint: uint256.Uint256): { low: bigint; high: bigint } {
  return {
    low: BigInt(uint.low.toString()),
    high: BigInt(uint.high.toString()),
  };
}
