# Intro

This repo contains assignments for "Blockchain and Decentralized Technologies" course by Distributed Lab.

## Task 1

### Implement cryptographic algorithm

Keccak hash algorithm was chosen. This implementation operates on big-endian LSB bit numbering *Message* and constant values.

### Message transformation example

1) Initial *Message*: `test`, Keccak-512 hash.
2) `test` --ord()--> `74 65 73 74` --> `01110100 01100101 01110011 01110100` (MSB) --> `00101110 10100110 11001110 00101110` (LSB)
3) `get_padding(Mbytes: '00101110 10100110 11001110 00101110', r=576, Mbits='')`<br>
    result: `00101110 10100110 11001110 00101110 10000000 00000000 .... 00000000 00000001` - big-endian LSB<br>
    the same *Message* could be represented in little-endian MSB:<br>
    `74 65 73 74 01 00 .... 00 80` in HEX.
4) Here is the state in `absorb(Pi)` function before applying Keccak-f[1600]

``` C
[['00101110 10100110 11001110 00101110 10000000 000000000000000000000000', '00...00', '00...00', '00...00', '00...00'],
['00...00', '00...00', '00...00', '00...00', '00...00'],
['00...00', '00...00', '00...00', '00...00', '00...00'],
['00...00', '00000000000000000000000000000000000000000000000000000000 00000001', '00...00', '00...00', '00...00'],
['00...00', '00...00', '00...00', '00...00', '00...00']]
```

5) ....

### Supported hash functions

**Note:** whereis internals of Keccak and SHA3 are the same, the padding function differs, so hashes would be different.

| Hash instance       | r  | c  |Digest length(bits)|
|---------------------|----|----|-------------------|
|Keccak224 / SHA3_224 |1152| 448| 224               |
|Keccak256 / SHA3_256 |1088| 512| 256               |
|Keccak384 / SHA3_384 | 832| 768| 384               |
|Keccak512 / SHA3_512 | 576|1024| 512               |

### Usage example

Get the Keccak-512 message hash:

``` Python
k512 = Keccak512(b'Message part 1')
k512.absorb(b'Message part 2')
print(k512.hexdigest(fmt='str'))
```

Get the SHA3-512 file hash:

``` Python
sha3_512 = SHA3_512()
with open('<file_name>', 'rb') as f:
    sha3_512.absorb(f)
print(f"SHA3-512 hash for '<file_name>' file is {sha3_512.hexdigest()}")
```
