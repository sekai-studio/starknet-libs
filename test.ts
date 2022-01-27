import { feltArrToStr, shortStringFeltToStr, strToFeltArr, strToShortStringFelt } from './lib/starknet-ts/utils';

const P = 2n ** 251n + 17n * 2n ** 192n + 1n;

const _str =
  // eslint-disable-next-line max-len
  'https://api.sorare.com/api/v1/cards/61970681423462123141329521425681429377512891414034252049050769480966097181246';

const CHAR_SIZE = BigInt(16 ** 2);

const str_n = strToShortStringFelt(_str);

function solution2() {
  const rem: bigint[] = [];
  let _str_n = str_n;
  while (_str_n > P) {
    rem.push(_str_n % P);
    _str_n /= P;
  }

  console.log(rem.length);
  console.log(rem);
  console.log(_str_n);
  console.log(str_n < P ** 4n);
  console.log(P ** 3n < str_n);

  const rebuilt =
    _str_n * P ** BigInt(rem.length) +
    rem.reduce((acc, val, i) => {
      return acc + P ** BigInt(i) * val;
    }, 0n);

  console.log(shortStringFeltToStr(rebuilt));
  console.log('Max str len', 31 * (rem.length + 1));
  console.log('N° val to return', rem.length + 1);
}

function solution3() {
  const length_n = BigInt(_str.length);

  const ns_r_str_n = str_n - CHAR_SIZE ** (length_n - 1n);
  console.log('256^(lenght-1)', (CHAR_SIZE ** (length_n - 1n)).toString(16));
  console.log('ns_r_str_n', ns_r_str_n.toString(16));

  const r_str_n = ns_r_str_n >> ((length_n - 1n) * 8n);
  console.log('r_str_n', r_str_n.toString(16));
  console.log('<= MAX_INT', r_str_n <= P);

  const rebuilt_str_r = (r_str_n << ((length_n - 1n) * 8n)) + CHAR_SIZE ** (length_n - 1n);
  console.log('rebuilt_r_str_n', rebuilt_str_r.toString(16));
  console.log(shortStringFeltToStr(rebuilt_str_r));
}

function solution5() {
  const length = 150n;

  const min = CHAR_SIZE ** (length - 1n);
  const max = CHAR_SIZE ** (length + 1n);

  const str_n = max - 1n;

  const rem = str_n % min;
  const qot = str_n / min;

  console.log(rem);
  console.log(qot);
  console.log(min * qot + rem === str_n);
  console.log(rem <= P);
}

function solution6() {
  // eslint-disable-next-line quotes
  const a_str = "Hello, my name is Jag. I'm the CTO of Sekai.";
  const n = BigInt(a_str.length);
  const a = strToShortStringFelt(a_str);
  const a_1 = 256n ** (n - 1n);
  const q = a / a_1;
  const r = a % a_1;

  console.log(a.toString(2));
  console.log(a.toString(16));
  console.log('---');
  console.log(q.toString(2));
  console.log(q.toString(16));
  console.log('---');
  console.log(r.toString(2));
  console.log(r.toString(16));
  console.log('---');
  console.log(shortStringFeltToStr(q * a_1 + r));
}

function solution7() {
  const str = 'Hello';
  const felts = strToFeltArr(str);
  console.log(felts);
  const newStr = feltArrToStr(felts);
  console.log(newStr);
}

function test() {
  const BASE_URI = 'https://api.sekai.gg/api/v1/assets/';
  const arr = strToFeltArr(BASE_URI);
  console.log(feltArrToStr(arr));
}

test();
