/** Short strings are useful to easily store strings on 31 characters or less though no manipulation is implemented once stored on-chain **/

/**
 * Converts a string into a short string numeral
 * (short strings cannot have more than 31 characters)
 * @param {string} str - The string to convert
 * @returns {bigint} - The short string hex value
 */
export function strToShortStringFelt(str: string): bigint {
  const strB = Buffer.from(str);
  return BigInt(
    strB.reduce((memo, byte) => {
      memo += byte.toString(16);
      return memo;
    }, '0x'),
  );
}

/**
 * Converts a short string numeral to a readable string
 * (short strings cannot have more than 31 characters)
 * @param {bigint} felt - The short string hex value
 * @returns {string} - The readable string
 */
export function shortStringFeltToStr(felt: bigint): string {
  const newStrB = Buffer.from(felt.toString(16), 'hex');
  return newStrB.toString();
}

/** Cairo Field Element Arrays allow for much bigger strings (up to 2^15 characters) and manipulation is implemented on-chain **/

/**
 * Converts a string into an array of numerical characters in utf-8 encoding
 * @param {string} str - The string to convert
 * @returns {bigint[]} - The string converted as an array of numerical characters
 */
export function strToFeltArr(str: string): bigint[] {
  const strArr = str.split('');
  return strArr.map(char => BigInt(Buffer.from(char)[0].toString(10)));
}

/**
 * Converts an array of utf-8 numerical characters into a readable string
 * @param {bigint[]} felts - The array of numerical characters
 * @returns {string} - The readable string
 */
export function feltArrToStr(felts: bigint[]): string {
  return felts.reduce((memo, felt) => memo + Buffer.from(felt.toString(16), 'hex').toString(), '');
}
