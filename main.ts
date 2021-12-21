const str = 'Hello';

const strB = Buffer.from(str);
const felt = BigInt(
  strB.reduce((memo, byte) => {
    memo += byte.toString(16);
    return memo;
  }, '0x'),
);

const newStrB = Buffer.from(felt.toString(16), 'hex');
const newStr = newStrB.toString();

console.log(newStr);
