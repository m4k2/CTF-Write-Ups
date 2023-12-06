## JAMBO
**EVM,PWN / 33 solves / 155 pts**

**Author: publicqi (@publicqi)**

### Challenge Background
```
Tony went crazy. No one knows what he has deployed on Ethereum. 
```
 The player's challenge is to bring the balance of this enigmatic contract to zero. The only clue available is the contract's bytecode, necessitating a reverse engineering approach.

[Challenge contract](util/Jambo/Challenge.sol)

#### Challenge Contract Mechanics
Participants interact with a contract named `Challenge`. This contract, upon deployment, performs the following actions:
- Deploys a new contract using a predefined bytecode and assigns its address to a variable called `target`.
- Utilizes the `Jambo` interface to invoke two specific functions on the target contract:
  1. `start` function with preset parameters, initializing certain operations.
  2. `revokeOwnership` function, altering the ownership state of the target.

```solidity
Jambo(target).start(0x1337, bytes32(0x66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64));

Jambo(target).revokeOwnership();
```

### Approach to Solving
1. **Decompilation of Target Contract:**
   - Utilize tools like [Dehaub](https://library.dedaub.com/decompile) or [Panoramix](https://github.com/eveem-org/panoramix) for reverse engineering the target's bytecode.
   - Be cautious, as decompilers can often produce inaccuracies, especially in CTF contexts.
   - The following link provides the code as decompiled by Dehaub: [Decompiled Target Contract](util/Jambo/Decompile.sol).

2. **Analysis of Key Functions:**
   - **`revokeOwnership`**: This function revokes ownership by setting the owner variable to a null address. This function is not crucial for solving the challenge.
   ```solidity
   function revokeOwnership() public nonPayable {

      // Check if msg.data.length == 4
      0xa5(4, msg.data.length);

      // Set the memory pointer
      0x149(MEM[64], 52);

      // Set v0 to 1 
      v0 = 0x501(1);

      // Check if msg.sender is the Owner
      require(STORAGE[keccak256(msg.sender)] == v0);

      // Set the Ownership to false
      STORAGE[keccak256(msg.sender)] = 0;
      return ;
   }
   ```
   - **`start`**: Sets two critical variables based on the input parameters. The function prepares the ground for the challenge-solving strategy.
   ```solidity
   function start(uint256 tokenId, bytes32 spellHash) public payable { 

      // Check if msg.data.length is 1 selector (4 bytes) and 2 variables (2*32 bytes)
      require(msg.data.length - 4 >= 64);

      // ?? Decompilation error imo
      if ((keccak256(msg.sender) >> 248) - 55) {

         // Store tokenId in _questionId
         _questionId = tokenId;

         // Set fmp
         0x149(MEM[64], 64);

         // Store keccak256(spellHash) in stor_1
         stor_1 = uint256(keccak256(spellHash));

         // Set fmp
         0x149(MEM[64], 52);

         // CHeck if msg.sender is the owner
         v0 = 0x501(1);
         require(STORAGE[keccak256(msg.sender)] == v0); // require mapping(msg.sender) ==> TRUE
      
      }
      return ;
   }
   ```

3. **The Crux of the Challenge - `answer` Function:**
   - The solution hinges on the `answer` function, which is inferred from the challenge's interface.
   - The function requires an input that matches the `spellHash` set in the `start` function and an Ethereum transaction with a value greater than 1 ether.
   - When these conditions are met, the function transfers the entire balance of the target contract to the sender.
   ```solidity
   function 0x2f484947(bytes varg0) public payable { 
      //require(msg.data.length - 4 >= 32);
      require(varg0 <= uint64.max);
      require(4 + varg0 + 31 < msg.data.length);
      //require(varg0.length <= uint64.max, Panic(65)); // failed memory allocation (too much memory)
      v0 = new bytes[](varg0.length);
      0x149(v0, (varg0.length + 31 & ~0x1f) + 32); // set fmp 
      //require(varg0.data + varg0.length <= msg.data.length);
      CALLDATACOPY(v0.data, varg0.data, varg0.length); // put varg0 in memory 
      //v0[varg0.length] = 0; //out of length, more like delimiting the array 
      v1 = v0.length;
      v2 = v0.data;
      v3 = v4 = stor_1 == keccak256(v0); // == spelhash 
      if (v4) {
         v3 = msg.value > 10 ** 18; //need > 1 ether 
      }
      if (v3) {
         v5 = v6 = msg.sender;
         v7 = this;
         v8 = v9 = 0;
         if (!v7.balance) { // Decompilation error
               v8 = 2300;
         }
         v11 = v6.call().value(v7.balance).gas(v8); // here
         require(v11, MEM[64], RETURNDATASIZE()); //require success
         require(msg.sender.code.size == 0); // require msg.sender == not SC
      }
      return ;
   }
   ```
   
   **The function primarily consists of four key sections**
   ```solidity
   v0 = new bytes[](varg0.length);
      0x149(v0, (varg0.length + 31 & ~0x1f) + 32); // set fmp 
      //require(varg0.data + varg0.length <= msg.data.length);
      CALLDATACOPY(v0.data, varg0.data, varg0.length); // put varg0 in memory 
   ```
   Store in `v0` `varg0`, with `varg0` the input of the function

   ```solidity
   v3 = v4 = stor_1 == keccak256(v0); // == spelhash 
   ```
   Check if `v0 == stor_1`, with `stor_1` previously set in the `start(uin256,bytes32)` function

   ```solidity
   if (v4) {
         v3 = msg.value > 10 ** 18; //need > 1 ether 
      }
   ```
   Check if `msg.value > 1 ether`

   ```solidity
   v5 = v6 = msg.sender;
   v7 = this;
   ...
   v11 = v6.call().value(v7.balance).gas(v8); // here
   ```
   Send all the `contract balance` to `msg.sender`
   

### Solution Script
- A foundry script is provided for executing the solution. It involves:
  - Setting up a connection with the `Jambo` interface.
  - Preparing the correct input data that aligns with the `spellHash`.
  - Sending a transaction with the required ether value to trigger the `answer` function and drain the target contract's balance.

   ```solidity
   bytes memory data = hex"66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64";
   
   Jambo(address(chall.target())).answer{value : 1.1 ether}(data);
   ```

   Link to the solution script: [Solve Script](util/Jambo/Solve.s.sol)


![Thanks](util/img/giphy.gif)


<p align="center">
Feel free to pose your questions here: https://twitter.com/0x_m4k2
</p>

