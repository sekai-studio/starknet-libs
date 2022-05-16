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

```
pip install sekai-starknet-libraries
```

## Libraries

### String

Library to store & manipulate strings in Cairo on StarkNet.

_The doc needs to be written but the code is commented using Python Docstrings standards (kinda)_

### Math

Short utility to concatenate arrays. _Credits [Marcello Bardus](https://github.com/marcellobardus/starknet-l2-storage-verifier/blob/master/contracts/starknet/lib/concat_arr.cairo)_

_The doc needs to be written but the code is commented using Python Docstrings standards (kinda)_

## Local setup

```
pip install -r requirements.txt
```

Test: `make test`

Build packages: `make build`
