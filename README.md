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

| Hash instance        | r    | c    | Digest length(bits) |
|----------------------|------|------|---------------------|
| Keccak224 / SHA3_224 | 1152 | 448  | 224                 |
| Keccak256 / SHA3_256 | 1088 | 512  | 256                 |
| Keccak384 / SHA3_384 | 832  | 768  | 384                 |
| Keccak512 / SHA3_512 | 576  | 1024 | 512                 |

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

---

## Task 2

### Large numbers

Implement a program that:

1. Calculates and outputs the number of key options for 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096-bit sequences.
2. Generates a random key value within the specified range (0x00...0 to 0xFF...F) for each key length option.
3. Implements a brute force function to find the key by iterating over all values from 0x00...0 until the generated key is found. The function should output the time taken in milliseconds to find the key.

### Usage example

The program has a helper class `Key` that would generate a store the key with required bit length. It could be used as:

``` Python
key = Key(length=128)
print(f"Generated: {repr(key)}")
print(f"Key MSB bit order form: {key}")

Generated: <Key len: 128, space: 340282366920938463463374607431768211456, key: 0x1d8861dd9effc3ba165b5bd04dc2150a>
Key MSB bit order form: 0001 1101 1000 1000 0110 0001 1101 1101 1001 1110 1111 1111 1100 0011 1011 1010 0001 0110 0101 1011 0101 1011 1101 0000 0100 1101 1100 0010 0001 0101 0000 1010
```

There are two functions that implement bruteforcing with multithread or multiprocessing:

``` Python
brute_multithread(key_length, num_threads)
brute_multiprocess(key_length, num_processes)
```

### Results

In the real-world scenario, key brute forcing would mean that we would initially have a key derivative value (hash or elliptic curve multiplication result, etc.). In that case, we would either enumerate key space, hashing the key candidates and comparing them to the target key hash, or use algorithms like baby-step giant-step to find the key. These methods are computationally intensive and usually feasible only on reduced key space (i.e., as in the Bitcoin puzzle, where private keys are generated explicitly with many zeroes in the beginning).

For this task, we just compare the key kanditate it to the target key.

I was able to "find" the key up to 32 bit. On 64 bit I stopped the program execution after a few hours.

| Key length | Key space            | Key in hex         | Time to find the key (ms) |
|------------|----------------------|--------------------|---------------------------|
| 8          | 256                  | 0xe7               | 1.92                      |
| 16         | 65536                | 0xc68f             | 6.94                      |
| 32         | 4294967296           | 0xec9cd386         | 536447.3                  |
| 64         | 18446744073709551616 | 0x5e1482cdb9e79b15 | --                        |

This concludes that even with small key size and no computationally heavy operations on the key candidate, it would take a lot of time to "recover" the key. For real-world key sizes and non-quantum processing power it would be just impossible.
