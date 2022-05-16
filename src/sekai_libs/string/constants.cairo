%lang starknet

const SHORT_STRING_MAX_LEN = 31  # The maximum character length of a short string
const SHORT_STRING_MAX_VALUE = 2 ** 248 - 1  # The maximum value for a short string of 31 characters (= 0b11...11 = 0xff...ff)
const CHAR_SIZE = 256  # Each character is encoded in utf-8 so 8-bit
const EXTRACT_CHAR_MASK = 2 ** 248 - CHAR_SIZE  # Mask to retreive the last character (= 0b11...1100000000)
const STRING_MAX_LEN = 2 ** 15  # The maximum index fot felt* in one direction given str[i] for i in [-2**15, 2**15) to allow back propagation for string inverse read/write operations
