import itertools
from math import log2
from bitarray import bitarray
from Crypto.Hash import keccak  # for results verification


RoundConstants = [
  0x0000000000000001,   0x0000000000008082,   0x800000000000808A,   0x8000000080008000,
  0x000000000000808B,   0x0000000080000001,   0x8000000080008081,   0x8000000000008009,
  0x000000000000008A,   0x0000000000000088,   0x0000000080008009,   0x000000008000000A,
  0x000000008000808B,   0x800000000000008B,   0x8000000000008089,   0x8000000000008003,
  0x8000000000008002,   0x8000000000000080,   0x000000000000800A,   0x800000008000000A,
  0x8000000080008081,   0x8000000000008080,   0x0000000080000001,   0x8000000080008008
]

RotationOffsets = [
  [ 0,  1, 62, 28, 27, ],
  [36, 44,  6, 55, 20, ],
  [ 3, 10, 43, 25, 39, ],
  [41, 45, 15, 21,  8, ],
  [18,  2, 61, 56, 14, ]
]


class KeccakState(object):
    """
    A keccak state container. Stores a 2d 5x5 array where each array element consists of a single word with w bits
    """
    def __init__(self, bitrate, b):
        self.bitrate = bitrate
        self.b = b
        self.lanew = self.b // 25
        self.s = [[b * bitarray('0', endian='little') for __ in range(5)] for _ in range(5)]

    def absorb(self, Pi):
        """
        Mixes in the given bitrate-length string to the state.
        """
        for y, x in itertools.product(range(5), range(5)):
            self.s[x][y] = (self.s[x][y][:self.bitrate] ^ Pi) + self.s[x][y][:-self.bitrate]

    def squeeze(self):
        """
        Returns the bitrate-length prefix of the state to be output.
        """
        out = bitarray('')
        for y, x in itertools.product(range(5), range(5)):
            out += self.s[x][y]
        return out


class KeccakHash(object):
    def __init__(self, bitrate: int, capacity: int, digest_size: int):
        assert digest_size in {224, 256, 384, 512}, "SHAKE is not supported. Digest size shout be one of 224, 256, " \
                                                    "384 or 512 bit."
        assert bitrate + capacity in (25, 50, 100, 200, 400, 800, 1600)
        self.w = 64  # w ∈ {1,2,4,8,16,32,64} - the state lane length
        self.b = 1600  # b=25w. b ∈ {25,50,100,200,400,800,1600} - the width of the permutation and the width of the
        # state in the sponge construction
        # c - capacity, r - bitrate
        _l = int(log2(self.w))
        self.n = 12 + 2 * _l
        self.digest_size = digest_size
        self.block_size = bitrate
        self.state = KeccakState(self.block_size, self.b)
        self.buffer = bitarray('')

    def __repr__(self):
        return f"<KeccakHash r: {self.block_size}, c: {self.b - self.block_size},digest: {self.digest_size}>"

    def keccak_f(self, A):
        for i in range(self.n):
            A = self.round(A, RoundConstants[i])
        return A
    
    def round(self, A, RC):
        def rot(value, shift: int, width: int):
            """
            Bitwise cyclic shift operation, moving bit at position i into position i+shift
            https://stackoverflow.com/questions/63759207/circular-shift-of-a-bit-in-python-equivalent-of-fortrans-ishftc
            """
            # return ((value << shift) % (1 << width)) | (value >> (width - shift))
            if shift == 0:
                return value
            return value[:-shift] + value[:shift]

        # θ step
        C = [A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4] for x in range(5)]
        # C = [reduce(xor, A[x]) for x in range(5)]
        D = [C[(x-1) % 5] ^ rot(C[(x+1) % 5], 1, self.w) for x in range(5)]
        for x in range(5):
            for y in range(5):
                A[x][y] ^= D[x]

        # ρ and π steps
        B = [[0]*5 for _ in range(5)]
        # B = [bitarray('0', endian='little') for _ in range(5)]
        for x in range(5):
            for y in range(5):
                B[y][(2*x + 3*y) % 5] = rot(A[x][y], RotationOffsets[y][x], self.w)

        # χ step
        for x in range(5):
            for y in range(5):
                A[x][y] = B[x][y] ^ ((~B[(x+1) % 5][y]) & B[(x+2) % 5][y])

        # ι step
        # A[0][0] = A[0][0] ^ RC
        A[0][0] = A[0][0] ^ bitarray(bin(RC)[2:].ljust(self.b, '0'), endian='little')
        return A

    @staticmethod
    def msg_to_bits(M: str):
        def access_bit(data, num):  # https://stackoverflow.com/questions/43787031/python-byte-array-to-bit-array
            base = int(num // 8)
            shift = int(num % 8)
            return (data[base] >> shift) & 0x1
        m_bytes = list(map(ord, M))
        return [access_bit(m_bytes, i) for i in range(len(m_bytes) * 8)]  # Message in big-endian LSB bit numbering

    @staticmethod
    def get_padding(Mbytes: list, bitrate: int, Mbits='01'):
        """
        https://cryptologie.net/article/387/byte-ordering-and-bit-numbering-in-keccak-and-sha-3/
        https://keccak.team/keccak_bits_and_bytes.html
        @param Mbytes: list of Message bytes
        @param bitrate:
        @return: padding bytearray
        """
        def access_bit(data, num):  # https://stackoverflow.com/questions/43787031/python-byte-array-to-bit-array
            base = int(num // 8)
            shift = int(num % 8)
            return (data[base] >> shift) & 0x1
        _m_bits = [access_bit(Mbytes, i) for i in range(len(Mbytes) * 8)]  # Message in big-endian LSB bit numbering
        m_bits = bitarray(_m_bits, endian='little')  # Message converted to bit array. NOT the same as Mbits!
        # craft delimiter + padding
        padding_len = bitrate - len(m_bits) % bitrate
        padding = bitarray(Mbits) + bitarray([1] + [0]*(padding_len-len(Mbits)-2) + [1])
        # construct the padded message and split in lanes
        m_bits += padding
        while len(m_bits) > 0:
            _b = bitarray(endian='little')
            _b.frombytes(m_bits[:bitrate].tobytes())
            m_bits = m_bits[bitrate:]
            yield _b

    def _absorb_block(self, Pi):
        assert len(Pi) == self.block_size
        # S[x,y] = S[x,y] xor Pi[x+5*y], for (x,y) such that x+5*y < r/w
        self.state.absorb(Pi)
        # S = Keccak-f[r+c](S)
        self.keccak_f(self.state.s)

    def absorb(self, P):
        self.buffer += KeccakHash.msg_to_bits(P)
        while len(self.buffer) >= self.block_size:
            self._absorb_block(self.buffer[:self.block_size])
            self.buffer = self.buffer[self.block_size:]

    def absorb_final(self):
        padded = next(self.get_padding(self.buffer, self.block_size))
        self._absorb_block(padded)
        self.buffer = []

    def squeeze_once(self):
        rc = self.state.squeeze()
        self.keccak_f(self.state.s)
        return rc

    def squeeze(self, l):
        Z = self.squeeze_once()
        while len(Z) < l:
            Z += self.squeeze_once()
        return Z[:l]
    
    def hexdigest(self, fmt='str'):
        self.absorb_final()
        digest = self.squeeze(self.digest_size)
        # return KeccakState.bytes2str(digest).encode('hex')
        dbytes = digest.tobytes()
        if fmt == 'hex':
            return dbytes
        elif fmt == 'str':
            return ''.join("{:02x}".format(b) for b in dbytes)
        else:
            raise ValueError('fmt should be hex or str')

    @staticmethod
    def preset(bitrate_bits, capacity_bits, output_bits):
        """
        Returns a factory function for the given bitrate, sponge capacity and output length.
        The function accepts an optional initial input, ala hashlib.
        """
        def create(initial_input=None):
            h = KeccakHash(bitrate_bits, capacity_bits, output_bits)
            if initial_input is not None:
                h.absorb(initial_input)
            return h
        return create


Keccak512 = KeccakHash.preset(576, 1024, 512)
print(Keccak512)

h = Keccak512('test').hexdigest(fmt='str')
# k = Keccak512()
# k.absorb('test')
# h2 = k.hexdigest()
print(h)

assert [*KeccakHash.get_padding([174, 188, 223], 16)] ==\
       [bitarray('0111 0101 0011 1101'), bitarray('1111 1011 0110 0001')]  # Check Keccak padding for [ae, bc, df]
