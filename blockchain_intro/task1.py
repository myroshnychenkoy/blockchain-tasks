import itertools
from typing import Type, List, Generator, BinaryIO
from io import IOBase
from math import log2
from bitarray import bitarray
from Crypto.Hash import keccak  # for results verification

RoundConstants = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
    0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008
]

RotationOffsets = [
    [0, 1, 62, 28, 27, ],
    [36, 44, 6, 55, 20, ],
    [3, 10, 43, 25, 39, ],
    [41, 45, 15, 21, 8, ],
    [18, 2, 61, 56, 14, ]
]


class KeccakState(object):
    """
    A Keccak state container. Stores a 2d 5x5 array where each array element consists of a single word of 'w' bits size
    """

    def __init__(self, bitrate: int, lane_width: int):
        self.bitrate = bitrate
        self.lanew = lane_width
        self.s = [[self.lanew * bitarray('0', endian='little') for __ in range(5)] for _ in range(5)]

    def absorb(self, Pi: bitarray):
        """
        Mixes in the given bitrate-length string to the state.
        """
        for pos in range(self.bitrate // self.lanew):
            x = pos % 5
            y = pos // 5
            self.s[x][y] ^= Pi[pos * self.lanew:(pos + 1) * self.lanew]

    def squeeze(self):
        """
        Returns the bitrate-length prefix of the state to be output.
        """
        out = bitarray('', endian='little')
        for pos in range(self.bitrate // self.lanew):
            x = pos % 5
            y = pos // 5
            out += self.s[x][y]
        return out


class KeccakHash(object):
    def __init__(self, bitrate: int, capacity: int, digest_size: int,):
        assert digest_size in {224, 256, 384, 512}, "SHAKE is not tested. Digest size shout be one of 224, 256, " \
                                                    "384 or 512 bit."
        self.b = bitrate + capacity  # b=25w. b ∈ {25,50,100,200,400,800,1600} - the width of the permutation
        # and the width of the state in the sponge construction
        assert self.b in (25, 50, 100, 200, 400, 800, 1600)
        self.w = self.b // 25  # w ∈ {1,2,4,8,16,32,64} - the state lane length
        _l = int(log2(self.w))
        self.n = 12 + 2 * _l
        self.digest_size = digest_size
        self.block_size = bitrate
        self.state = KeccakState(self.block_size, self.w)
        self.buffer = bitarray('', endian='little')

    def __repr__(self):
        return f"<KeccakHash r: {self.block_size}, c: {self.b - self.block_size}, digest: {self.digest_size}>"

    def keccak_f(self, A):
        for i in range(self.n):
            A = self.round(A, RoundConstants[i])
        return A

    def round(self, A, RC):
        def rot(value: bitarray, shift: int):
            """
            Bitwise cyclic shift operation, moving bit at position i into position i+shift
            https://stackoverflow.com/questions/63759207/circular-shift-of-a-bit-in-python-equivalent-of-fortrans-ishftc
            """
            # return ((value << shift) % (1 << width)) | (value >> (width - shift))
            return value if shift == 0 else value[-shift:] + value[:-shift]

        # θ step
        C = [A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4] for x in range(5)]
        D = [C[(x - 1) % 5] ^ rot(C[(x + 1) % 5], 1) for x in range(5)]
        for x, y in itertools.product(range(5), range(5)):
            A[x][y] ^= D[x]

        # ρ and π steps
        B = [[0] * 5 for _ in range(5)]
        for x, y in itertools.product(range(5), range(5)):
            B[y][(2 * x + 3 * y) % 5] = rot(A[x][y], RotationOffsets[y][x])

        # χ step
        for x, y in itertools.product(range(5), range(5)):
            A[x][y] = B[x][y] ^ ((~B[(x + 1) % 5][y]) & B[(x + 2) % 5][y])

        # ι step
        _RC = bitarray(endian='little')
        _RC.frombytes(RC.to_bytes(self.w // 8, byteorder='little'))
        A[0][0] = A[0][0] ^ _RC
        return A

    @staticmethod
    def get_padded(Mbytes: bitarray, bitrate: int) -> Generator[bitarray, None, None]:
        """
        https://cryptologie.net/article/387/byte-ordering-and-bit-numbering-in-keccak-and-sha-3/
        https://keccak.team/keccak_bits_and_bytes.html
        @param Mbytes: bitarray of Message bits in big-endian LSB bit numbering
        @param bitrate:
        @return: generator for padded Message parts in bitrate-sized chunks
        """
        m_bits = Mbytes.copy()
        # craft padding
        padding_len = bitrate - len(m_bits) % bitrate
        padding = bitarray([1] + [0] * (padding_len - 2) + [1])
        # construct the padded message and split in lanes
        m_bits += padding
        while len(m_bits) > 0:
            _b = bitarray(endian='little')
            _b.frombytes(m_bits[:bitrate].tobytes())
            m_bits = m_bits[bitrate:]
            yield _b

    @staticmethod
    def get_padded_from_bytearray(Mbytes: List[int], bitrate: int) -> Generator[bitarray, None, None]:
        """
        @param Mbytes: list of Message bytes
        @param bitrate:
        @param Mbits:
        @return: generator for padded Message parts in bitrate-sized chunks
        """

        def access_bit(data, num):  # https://stackoverflow.com/questions/43787031/python-byte-array-to-bit-array
            base = int(num // 8)
            shift = int(num % 8)
            return (data[base] >> shift) & 0x1

        _m_bits = [access_bit(Mbytes, i) for i in range(len(Mbytes) * 8)]  # Message in big-endian LSB bit numbering
        m_bits = bitarray(_m_bits, endian='little')  # Message converted to bit array. NOT the same as Mbits!
        return KeccakHash.get_padded(m_bits, bitrate)

    def _absorb_block(self, Pi):
        assert len(Pi) == self.block_size
        # S[x,y] = S[x,y] xor Pi[x+5*y], for (x,y) such that x+5*y < r/w
        self.state.absorb(Pi)
        # S = Keccak-f[r+c](S)
        self.keccak_f(self.state.s)

    def absorb(self, Mbytes: bytes | BinaryIO):
        """
        Absorb given bytes or file object to the sponge
        @param Mbytes: either bytes object or file binary handler
        """
        _P_bits = bitarray(endian='little')
        if isinstance(Mbytes, bytes):
            _P_bits.frombytes(Mbytes)
        elif isinstance(Mbytes, IOBase):
            _P_bits.fromfile(Mbytes)
        self.buffer += _P_bits
        while len(self.buffer) >= self.block_size:
            self._absorb_block(self.buffer[:self.block_size])
            self.buffer = self.buffer[self.block_size:]

    def absorb_final(self):
        padded = next(self.get_padded(self.buffer, self.block_size))
        self._absorb_block(padded)
        self.buffer = []

    def squeeze_once(self):
        rc = self.state.squeeze()
        self.keccak_f(self.state.s)
        return rc

    def squeeze(self, l):
        H = self.squeeze_once()
        while len(H) < l:
            H += self.squeeze_once()
        return H[:l]

    def hexdigest(self, fmt='str'):
        self.absorb_final()
        digest = self.squeeze(self.digest_size)
        dbytes = digest.tobytes()
        if fmt == 'hex':
            return dbytes
        elif fmt == 'str':
            return ''.join(f'{b:02x}' for b in dbytes)
        else:
            raise ValueError('fmt should be hex or str')


class SHA3Hash(KeccakHash):
    def __init__(self, bitrate: int, capacity: int, digest_size: int):
        """
        FIPS 202 utilises different padding method then 'original' Keccak. Instead of `M + 1 + 0*j + 1`
        it's now `M + d + 0*j + 1`, where d is a domain separation bits and equal 0x06 for SHA3 instances.
        """
        super().__init__(bitrate, capacity, digest_size)
        assert self.b == 1600
        # self.Mbits = '01'
        self.d = '011'  # 0x06 in LSB bit order

    def get_padded(self, Mbytes: bitarray, bitrate: int) -> Generator[bitarray, None, None]:
        m_bits = Mbytes.copy()
        # craft delimiter + padding
        padding_len = bitrate - len(m_bits) % bitrate
        padding = bitarray(self.d) + bitarray([0] * (padding_len - len(self.d) - 1) + [1])
        # construct the padded message and split in lanes
        m_bits += padding
        while len(m_bits) > 0:
            _b = bitarray(endian='little')
            _b.frombytes(m_bits[:bitrate].tobytes())
            m_bits = m_bits[bitrate:]
            yield _b


def KeccakFamilyFactory(subset_class: Type[KeccakHash], bitrate_bits: int, capacity_bits: int, digest_bits: int):
    """
    Returns a factory function for the given bitrate, sponge capacity and output (digest) length.
    The function accepts an optional initial input, ala hashlib.
    """
    def create(initial_input=None):
        keccak_obj = subset_class(bitrate_bits, capacity_bits, digest_bits)
        if initial_input is not None:
            keccak_obj.absorb(initial_input)
        return keccak_obj
    return create


Keccak224 = KeccakFamilyFactory(subset_class=KeccakHash, bitrate_bits=1152, capacity_bits=448, digest_bits=224)
Keccak256 = KeccakFamilyFactory(subset_class=KeccakHash, bitrate_bits=1088, capacity_bits=512, digest_bits=256)
Keccak384 = KeccakFamilyFactory(subset_class=KeccakHash, bitrate_bits=832, capacity_bits=768, digest_bits=384)
Keccak512 = KeccakFamilyFactory(subset_class=KeccakHash, bitrate_bits=576, capacity_bits=1024, digest_bits=512)

SHA3_224 = KeccakFamilyFactory(subset_class=SHA3Hash, bitrate_bits=1152, capacity_bits=448, digest_bits=224)
SHA3_256 = KeccakFamilyFactory(subset_class=SHA3Hash, bitrate_bits=1088, capacity_bits=512, digest_bits=256)
SHA3_384 = KeccakFamilyFactory(subset_class=SHA3Hash, bitrate_bits=832, capacity_bits=768, digest_bits=384)
SHA3_512 = KeccakFamilyFactory(subset_class=SHA3Hash, bitrate_bits=576, capacity_bits=1024, digest_bits=512)


if __name__ == "__main__":
    assert [*KeccakHash.get_padded_from_bytearray([174, 188, 223], 16)] == \
        [bitarray('0111 0101 0011 1101'),
         bitarray('1111 1011 1000 0001')], "Check Keccak padding for [\\xae, \\xbc, \\xdf]"

    # Assert with PyCryptodome result
    assert Keccak512(b'test').hexdigest(fmt='str') == keccak.new(data=b'test', digest_bits=512).hexdigest()

    # Test long message
    k512 = Keccak224()
    k512.absorb(b'Qw(FXICF9hxntm-Cf1y%3*ef-*#^A5FP6=P-U^cx_u_PK6H6+((k4+Ic42+ulnYQy8*RtGR_#mR^_msn+O-b-6OF#KHA^A-N)$-21'
                b'e1q6GGFZxL!78qkbA_++9q-0cws*-w/BjbW1vr/hZbDT(54=WsSb(nUFMp7_VN2G939+o)G#Ap1c%pMsgWG%7usbxvR4b(Z$mUl%')
    assert k512.hexdigest(fmt='str') == '3c8ec3aec3e2841b922fea51b922e2fbab522275aaf89cd6d9233c6a'

    # Hash the file
    k512 = Keccak512()
    with open('requirements.txt', 'rb') as f:
        k512.absorb(f)
    print(f"Keccak-512 hash for 'requirements.txt' file is {k512.hexdigest()}")

    # SHA3-512 text test
    # https://www.di-mgt.com.au/sha_testvectors.html
    # Can take a few seconds to calculate:
    # the_long_a = b'a' * 1000000
    # assert SHA3_512(the_long_a).hexdigest(fmt='str') == \
    #        '3c3a876da14034ab60627c077bb98f7e120a2a5370212dffb3385a18d4f38859' \
    #        'ed311d0a9d5141ce9cc5c66ee689b266a8aa18ace8282a0e0db596c90b0a7b87'

    sha3_512 = SHA3_512()
    with open('requirements.txt', 'rb') as f:
        sha3_512.absorb(f)
    print(f"SHA3-512 hash for 'requirements.txt' file is {sha3_512.hexdigest()}")
