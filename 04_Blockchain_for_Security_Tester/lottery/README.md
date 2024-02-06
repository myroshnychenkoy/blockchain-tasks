## Task

Design and implement a lottery smart contract on the Ethereum platform with specific constraints. The lottery system should be secure, transparent, and ensure fair participation. Users should be able to participate by sending the entry request, with the proceeds being distributed to the winners automatically. The smart contract must have the following constraints:
- The lottery smart contract can have only one owner/administrator.
- A minimum of 3 users is required to participate in the lottery.
- The administrator cannot participate as a user in the lottery.
- The minimum ticket price (lot) is 0.5 Ether.
- Only the administrator can pick the winner, either randomly or using a pseudorandom method.

### Deliverables
Solidity smart contract code file(s) implementing the lottery system.

### [Optional]
Integrate randomness: Integrate a secure and decentralized source of randomness using [Chainlink VRF](https://docs.chain.link/vrf) for selecting the winner and get rid of preudorandom


## Solution

### v1 - pseudorandom

Additional features were introduced:
- "locked" state - no one can longer participate, lottery is avaiting winner to be choosed. Could be triggered only by the Owner. Also, it sets the target block number to be used as part of the seed in the PRNG.
- a few fairness features (ensures that Ether is not stuck in the contract):
    - user can refund the money
    - user can trigger the reveal of the winner when target block is reached
- owner gets a 1% fee from the lottery pool

PRNG is based on two seeds:
- blockhash of the target block in the future;
- secret seed provided by any user or the owner. Confidentiality and fairness guaranteed by the commit-reveal scheme.

### v2 - Chainlink VRF

> Foundry deployment scripts for the Chinlink VRF mocks were reused from <https://github.com/justin-moss-swd/Solidity_Foundry_Lottery>.


## Research & References

- Beware of insecure randomness - https://owasp.org/www-project-smart-contract-top-10/2023/en/src/SC08-insecure-randomness.html
- https://github.com/axiomzen/eth-random - "RNG on Ethereum blockchain" CryptoKitties example
- https://soliditydeveloper.com/prevrandao - Solidity Deep Dive: New Opcode 'Prevrandao'
- https://medium.com/coinmonks/how-to-generate-random-numbers-in-solidity-16950cb2261d - overview of a "hash-based" PRNG, on-chain and off-chain VRFs, Commit-Reveal Scheme
- https://medium.com/coinmonks/commit-reveal-scheme-in-solidity-c06eba4091bb - Commit-Reveal Scheme example
- safe element delete from arrays - https://blog.solidityscan.com/improper-array-deletion-82672eed8e8d
- https://medium.com/@solidity101/demystifying-the-delete-keyword-in-solidity-unveiling-its-secrets-265943c42537
- https://docs.soliditylang.org/en/latest/units-and-global-variables.html
- https://github.com/Cyfrin/Updraft/tree/main/courses/foundry/4-smart-contract-lottery

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.** | Documentation: https://book.getfoundry.sh/

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Usage

### Build

```shell
$ forge build
```

### Test

> ⚠️ Note that tests for this project are not meant to be exhaustive. This is a playground to test GetFoundry's features.

```shell
$ forge test -vvv
$ forge test --via-ir --optimize -vvv --fail-fast --match-path ./test/Lottery_v2_ChainlinkVRF.t.sol
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
