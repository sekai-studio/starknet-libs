# Sekai StarkNet Libraries

A series of libraries to help using Cairo on StarkNet.

Examples for use in other Cairo contracts are provided in [examples](examples).

## Contents

- [Usage](#usage)
- [Libraries](#libraries)
  - [String](#string)
  - [Math](#math)
- [Local setup](#local-setup)

## Usage

To use the libary, simply install it using

```bash
pip install sekai-starknet-libraries
```

To use the librairy in contracts then

```cairo
# contracts/MyContract.cairo

%lang starknet

from sekai_libs.string.store import String_set, String_get, String_delete
```

## Libraries

### String

Library to store & manipulate strings in Cairo on StarkNet.

_The doc needs to be written but the code is commented using Python Docstrings standards (kinda)_

### Math

Short utility to concatenate arrays. _Credits [Marcello Bardus](https://github.com/marcellobardus/starknet-l2-storage-verifier/blob/master/contracts/starknet/lib/concat_arr.cairo)_

_The doc needs to be written but the code is commented using Python Docstrings standards (kinda)_

## Local setup

```bash
pip install -r requirements.txt
```

### M1 mac installation issues

If you run into a `gmp.h` issue while trying to install `cairo-lang` on an M1 Mac, try running

```
CFLAGS=-I`brew --prefix gmp`/include LDFLAGS=-L`brew --prefix gmp`/lib pip install ecdsa fastecdsa sympy
```

Test: `make test`

Build packages: `make build`
