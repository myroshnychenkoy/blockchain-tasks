import time
import secrets
from typing import Literal
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor, as_completed
from threading import Event
from multiprocessing.managers import SyncManager


class Key(object):
    def __init__(self, length: Literal[8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]):
        self.length = length
        self.space = 2 ** self.length
        self.key = self.generate_random_key()

    def __len__(self):
        return self.length

    def __repr__(self):
        return f"<Key len: {self.length}, space: {self.space}, key: {hex(self.key)}>"

    def __index__(self):
        return self.key

    def __str__(self):
        bin_key = bin(self.key)[2:]
        len_key = len(bin_key)
        if len_key % 8:
            bin_key = bin_key.zfill(len_key + (8 - len_key % 8))
        return ' '.join(bin_key[i:i + 4] for i in range(0, len(bin_key), 4))

    def generate_random_key(self):
        return secrets.randbelow(2 ** self.length)


def brute_key_m(key: Key, idx_start: int, idx_end: int, halt_event: Event):
    for i in range(idx_start, idx_end):
        if halt_event.is_set():
            return 1
        if i == key.key:
            halt_event.set()
            return 0


def brute_multithread(key_length: int, num_threads: int):
    key = Key(length=key_length)
    print(f"Generated: {repr(key)}")
    print(f"Key MSB bit order form: {key}")

    start = time.perf_counter()
    halt_event = Event()

    with ThreadPoolExecutor() as executor:
        chunk_size = key.space // num_threads + 1
        functions = []

        for i in range(num_threads):
            function = executor.submit(brute_key_m,
                                       *(key, chunk_size * i,
                                         (chunk_size * (i + 1)) if (chunk_size * (i + 1)) < key.space else key.space,
                                         halt_event))
            functions.append(function)

        print([func.result() for func in as_completed(functions)])

    finish = time.perf_counter()
    print(f'The key {hex(key)} was found in {(finish - start) * 1000} milliseconds')


def brute_multiprocess(key_length: int, num_processes: int):
    key = Key(length=key_length)
    print(f"Generated: {repr(key)}")
    print(f"Key MSB bit order form: {key}")

    start = time.perf_counter()

    with SyncManager() as manager:
        halt_event = manager.Event()
        with ProcessPoolExecutor() as pool:
            chunk_size = key.space // num_processes + 1
            functions = []

            for i in range(num_processes):
                function = pool.submit(brute_key_m,
                                           *(key, chunk_size * i,
                                             (chunk_size * (i + 1)) if (chunk_size * (
                                                         i + 1)) < key.space else key.space,
                                             halt_event))
                functions.append(function)

            print([func.result() for func in as_completed(functions)])

    finish = time.perf_counter()
    print(f'The key {hex(key)} was found in {(finish - start) * 1000} milliseconds')


if __name__ == "__main__":
    for key_len in [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096]:
        brute_multiprocess(key_len, 16)
        print('\n\n')
