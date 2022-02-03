# Sekai StarkNet Libraries

A series of libraries to help using Cairo on StarkNet.

Examples for use in other Cairo contracts are provided in [examples](examples).

## Contents
- [Local run](#local-run)
- [Libraries](#libraries)
  - [String](#cairo-string)

## Local run
```
pip install -r requirements.txt
yarn
```
To run the tests use one terminal for the local devnet
```
yarn net
```
And a second one to test
```
yarn test
```

## Libraries
### Cairo String
Library to store & manipulate strings in Cairo on StarkNet.

Utilities to use those strings in TypeScript apps are located [here](utils/cairo_string.utils.ts).

_The doc needs to be written but the code is commented using Python Docstrings standards (kinda)_
