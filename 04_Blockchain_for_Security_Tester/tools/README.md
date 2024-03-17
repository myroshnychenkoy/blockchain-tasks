# This section is all about testing various security tools

## Vulnerable smart contracts used

- https://github.com/crytic/not-so-smart-contracts

## SAST | Slither

### Insecure Randomness

#### theRun

```bash
export SOLC_VERSION=0.4.0; slither not-so-smart-contracts/bad_randomness/theRun_source_code/theRun.sol
```

Successfully detected the insecure randomness in `theRun`

```Python
theRun.Participate(uint256) () uses a weak PRNG: "roll % 10 == 0 ()"
theRun.random(uint256) () uses a weak PRNG: "uint256((h / x)) % Max + 1 ()"
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG
```

### Denial of Service

```bash
export SOLC_VERSION=0.4.15; slither not-so-smart-contracts/denial_of_service/auction.sol
```

> [!WARNING]  
> DoS was not detected by Slither.

### Forced Ether Reception
- https://solidity-by-example.org/hacks/self-destruct/

```bash
SOLC_VERSION=0.4.25 slither not-so-smart-contracts/forced_ether_reception/coin.sol
```

Slither flagged the dangerous check:

```Python
MyAdvancedToken.migrate_and_destroy() (not-so-smart-contracts/forced_ether_reception/coin.sol#173-176) uses a dangerous strict equality:
        - assert(bool)(this.balance == totalSupply) (not-so-smart-contracts/forced_ether_reception/coin.sol#174)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
```

### Integer Overflow

```bash
SOLC_VERSION=0.4.15 slither not-so-smart-contracts/integer_overflow/integer_overflow_1.sol
```

> [!WARNING]
> Possible integer overflow was not detected by Slither.

### Race Condition

```bash
SOLC_VERSION=0.4.16 slither not-so-smart-contracts/race_condition/RaceCondition.sol
```

> [!WARNING]
> Potential for the race condition was not flagged by Slither.

### Reentrancy

#### The DAO

> [!NOTE]
> "The DAO" requires an old v0.3.1 version of Solidity. It's tricky to compile it, so I was unable to test it.

```bash
slither mainet:0xbb9bc244d798123fde783fcc1c72d3bb8c189413 # The DAO
```

#### SpankChain

```bash
SOLC_VERSION=0.4.23 slither not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol
```

Reentrancy found:

```python
Reentrancy in LedgerChannel.LCOpenTimeout(bytes32) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#414-429):
        External calls:
        - require(bool,string)(Channels[_lcID].token.transfer(Channels[_lcID].partyAddresses[0],Channels[_lcID].erc20Balances[0]),CreateChannel: token transfer failure) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#422)
        External calls sending eth:
        - Channels[_lcID].partyAddresses[0].transfer(Channels[_lcID].ethBalances[0]) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#419)
        State variables written after the call(s):
        - delete Channels[_lcID] (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#428)
        LedgerChannel.Channels (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#372) can be used in cross function reentrancies:
        - LedgerChannel.Channels (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#372)
        - LedgerChannel.LCOpenTimeout(bytes32) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#414-429)
        - LedgerChannel.byzantineCloseChannel(bytes32) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#748-809)
        - LedgerChannel.closeVirtualChannel(bytes32,bytes32) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#717-744)
        - LedgerChannel.consensusCloseChannel(bytes32,uint256,uint256[4],string,string) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#487-538)
        - LedgerChannel.createChannel(bytes32,address,uint256,address,uint256[2]) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#374-412)
        - LedgerChannel.deposit(bytes32,address,uint256,bool) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#457-484)
        - LedgerChannel.getChannel(bytes32) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#829-858)
        - LedgerChannel.initVCstate(bytes32,bytes32,bytes,address,address,uint256[2],uint256[4],string) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#607-649)
        - LedgerChannel.joinChannel(bytes32,uint256[2]) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#431-452)
        - LedgerChannel.settleVC(bytes32,bytes32,uint256,address,address,uint256[4],string) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#654-715)
        - LedgerChannel.updateLCstate(bytes32,uint256[6],bytes32,string,string) (not-so-smart-contracts/reentrancy/SpankChain_source_code/SpankChain_Payment.sol#542-604)
```


### Unchecked external call

#### King of the Ether

```bash
SOLC_VERSION=0.4.19 slither not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol
```

Slither found the unchecked external calls:

```Python
KingOfTheEtherThrone.claimThrone(string) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#95-158) ignores return value by msg.sender.send(valuePaid) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#101)
KingOfTheEtherThrone.claimThrone(string) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#95-158) ignores return value by msg.sender.send(excessPaid) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#108)
KingOfTheEtherThrone.claimThrone(string) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#95-158) ignores return value by currentMonarch.etherAddress.send(compensation) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#121)
KingOfTheEtherThrone.sweepCommission(uint256) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#161-163) ignores return value by wizardAddress.send(amount) (not-so-smart-contracts/unchecked_external_call/KotET_source_code/KingOfTheEtherThrone.sol#162)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unchecked-send
```

### Unprotected function

```bash
SOLC_VERSION=0.4.15 slither not-so-smart-contracts/unprotected_function/Unprotected.sol
```

> [!WARNING]
> It's a business logic bug. Unprotected function was not detected by Slither.

### Variable shadowing

```bash
SOLC_VERSION=0.4.25 slither not-so-smart-contracts/variable\ shadowing/inherited_state.sol
```

Detected by Slither:

```Python
C.owner (not-so-smart-contracts/variable shadowing/inherited_state.sol#9) shadows:
        - Suicidal.owner (not-so-smart-contracts/variable shadowing/inherited_state.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variable-shadowing
```

> [!TIP]
> Interestingly enough, on `SOLC_VERSION=0.8.23` compilation failed with error
> ```
> Error: Identifier already declared.
>   --> not-so-smart-contracts/variable shadowing/inherited_state.sol:11:5:
>    |
> 11 |     address owner;
>    |     ^^^^^^^^^^^^^
> Note: The previous declaration is here:
>  --> not-so-smart-contracts/variable shadowing/inherited_state.sol:2:5:
>   |
> 2 |     address owner;
>   |     ^^^^^^^^^^^^^
> ```
> It seems that the compiler is now more strict about shadowing.

### Wrong constructor name

#### Rubixi

```bash
SOLC_VERSION=0.4.15 slither not-so-smart-contracts/wrong_constructor_name/Rubixi_source_code/Rubixi.sol
```

> [!WARNING]
> This is a logic error. Slither did not flag anything suspicious in the wrongly named constructor.
