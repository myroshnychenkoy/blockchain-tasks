# Tasks

## Task 1 - Deploy a simple Solidity smart contract to Sepolia network

You will have to deploy and verify a “Hello world” smart contract on Sepolia network.

1. Download and create a Metamask account. Do not share the seed phrase with anyone.
2. Get some test ether on a dedicated faucet. [Here](https://sepoliafaucet.com/) or [Here](https://faucet.quicknode.com/ethereum/sepolia), for example.
3. Go to [remix](https://remix.ethereum.org/), create a new file, and paste the following code:

    ``` Solidity
    pragma solidity 0.8.19;

    contract HelloWorld {
       string public greet;

       constructor(string memory name) {
           require(bytes(name).length > 0, "name can't be empty");

           greet = string.concat("Hello world, my name is ", name);
       }
    }
    ```

4. Compile the file with the Solidity 0.8.19 compiler and optimization off.
5. Connect your metamask account to remix and choose Sepolia network.
6. Deploy the contract to Sepolia and provide your name to the smart contract constructor.
7. Search your contract by address on <https://sepolia.etherscan.io/> , click "Contract" and "Verify and Publish"
    Follow the instructions there and verify the contract:
   - Compiler Type is "Solidity (Single file)".
   - License Type is "No License".
   - Constructor arguments ABI-encoded can be obtained here. Use the “string” constructor argument to get the encoding.
8. Follow the instructions in remix and verify the contract. The hex encoding can be obtained [here](https://abi.hashex.org/). Use the “string” constructor argument to get the encoding.
9. Open your contract page again. "Contract" -> "Read contract" -> call the method "greet". You should now get a greeting string with the name you specified when you deployed the contract.

---

## Task 2 - Get acquainted with the data types in Solidity

Create a smart contract with a majority of different data types in it.

1. Each type should be declared as a storage variable - meaning not inside the function but inside the contract itself.
2. Also, SC should have functions to return all declared values. Interface for those functions will be provided and your contract should inherit it.
3. The interface will be provided in the task folder as a .sol file.
4. Each variable should have non-zero value!
5. The string field should contain the words - “Hello World!”.

The smart contract should also have one interesting function. Read the instructions carefully.

1. Function `getBigUint()` should return the uint256 value bigger than 1_000_000.
    For doing this you will only have 2 fields inside the function:

    ``` Solidity
    uint256 v1 = 1
    uint256 v2 = 2
    ```

2. Any arithmetical operator can be used only once, as an example:

    ``` Solidity
    return v1 + v2 - ok
    return v1 + v2 + v2 - not ok.
    ```

3. Only values v1 and v2 can be used.  

Once you are sure your contract compiles and works correctly, your next step is to deploy it on a test network. Will use Sepolia here again, because you already should have some test ETH.

For doing this task it is recommended to use Remix.

Once you created and deployed your contract you can check it with the validator smart contract.

For making it you will need to follow the link to etherscan and pass your SС address to the function `check(address _yourContract)` on the validator contract.

Getting the status true would mean that everything is done correctly.

---

## Task 3 - Solidity Functions and Reentrancy Attack

Implement a Vault contract and follow the provided specifications for the `withdrawSafe()` and `withdrawUnsafe()` functions. Create an Attacker contract and follow the provided specifications for the `depositToVault()` and `attack()` functions.

### Contract Vault

Implement the following functions on the Vault contract as described in the task description:

- `withdrawSafe(address payable holder)` - should send **via call** to the holder ether that they deposited to the contract (balance mapping).
    **Must revert** in case of reentrancy attack.
    Must reset the holder’s balance mapping after execution to zero.
- `withdrawUnsafe(address payable holder)` - should send **via call** to the holder ether that they deposited to the contract.
    **Must allow** a reentrancy attack.
    Must reset the holder’s address balance after execution to zero.

### Contract Attacker

Implement the following functions as described:
`attack()` and `fallback()` - must withdraw all ether from Vault, using the withdrawUnsafe() function including ether that is not deposited by the attacker's contract.

### What to hand in

1. Deploy the Vault contract.
2. Deploy the Attacker contract.
3. Deposit additional ether to Vault not from the Attacker contract. No more than `0.001` ether.
4. In the [Validator](./Task3_Validator.sol) contract, call `validate(address vault, address attacker)` to check the correctness of task implementation.

---

## Task 4 - Solidity inheritance

Implement contract D that inherits from B and C contracts. You are not allowed to change anything aside from contract D.

1. Make the contract D deployable. You will have to solve a tiny puzzle for that.
2. Private variable c in the C contract (that you can’t change yourself) should equal “2” after the D contract deployment.
3. Private variable deposited in the contract A should be > 0 at the end of validation.

---

## Task 5 - Solidity assembly & data locations

Implement contract `StrangeCalculator` in such a way that changes private variables one and pointMap in the inherited contract. Of course, high-level Solidity will not allow you to do that, however, the assembly will.

1. Implement `setNewValues` function in the StrangeClculator contract. You are not allowed to change anything else.
2. The call to `setNewValues` function should change private variables one and pointMap with the key `[12]` to parameters first and point. Use assembly for that.
3. Use the [validator](Task5_Validator.sol) contract to check if you have implemented the task correctly.
