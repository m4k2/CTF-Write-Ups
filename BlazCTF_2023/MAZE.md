## MAZE 
**YUL / 24 solves / 190 pts**
 
**Author: publicqi (@publicqi)**



### Background of the Challenge
```
Tony made billions $ from rug pulling. He bought an island in Fiji, started to study philosophy, and devoted to learning labyrinth.
```
In this challenge, players aim to navigate out of a maze by manipulating a player's position on a 2D grid, adjusting the x and y coordinates.

[View the Challenge Contract](util/Maze/Challenge.sol)

### The Maze Explained

The maze, crafted in Yul, can be explored here: [Maze.yul](util/Maze/Maze.yul)

Let's break down the key parts of the challenge:

#### Maze Initialization and Layout
- The contract sets up the maze using Ethereum's storage (`sstore`). Each cell in the grid is denoted by a byte, representing various elements like empty space, walls, the player, the exit, and invalid areas.
- The maze is laid out across several storage slots (`0x0` to `0xa`), where each slot contains a row of the maze.
- Additional slots (`0xb` to `0xe`) track the player's coordinates and other game aspects.

```solidity
  // Sprite Types:
    // 0x00 => Empty
    // 0x01 => Wall
    // 0x02 => Player
    // 0x03 => Exit
    // 0xff => Invalid
    code {
        // [Maze initialization code is omitted for brevity]
    }
  ```

#### Maze_Runtime: The Game Logic
This section of the code governs the game's operation when the contract is called.

1. **Game Completion Check:**
   - If `calldatasize()` equals `0x20`, the contract reveals whether the game has been solved by returning the value in slot `0xd`.
    ```solidity
        // return isSolved
        if eq(calldatasize(), 0x20) {
            mstore(0x0, sload(0xd))
            return (0, 0x20)
        }
    ```

2. **Player Movement Mechanics:**
   - The player's movement is determined by the `caller` address or the size of the call data (`calldatasize()`).
   - Specific Ethereum addresses correspond to movement directions (e.g., `-x`, `+y`).
   - Private keys for these addresses are accessible on [privatekeyfinder.io](https://privatekeyfinder.io/private-keys/ethereum/2).
   - The `switch` statement updates the player's position based on these inputs.
   - The [verbatim](https://docs.soliditylang.org/en/latest/yul.html#verbatim) instruction def : The set of verbatim... builtin functions lets you create bytecode for opcodes that are not known to the Yul compiler. It also allows you to create bytecode sequences that will not be modified by the optimizer.
   
    ```solidity
        // Game starts here
        let msg_sdr := caller()
        switch msg_sdr 
        // 0x46
        case 0xF9A2C330a19e2FbFeB50fe7a7195b973bB0A3BE9 { // -y
            verbatim_0i_0o(hex"6001600c5403600c55")
        }
        // 0x75
        case 0x2ACf0D6fdaC920081A446868B2f09A8dAc797448 { // -x
            sstore(0xb, sub(sload(0xb), 1))
        }
        // 0x7a
        case 0x872917cEC8992487651Ee633DBA73bd3A9dcA309 { // +y
            verbatim_0i_0o(hex"6001600c5401600c55")
        }
        // 0x5a
        case 0x802271c02F76701929E1ea772e72783D28e4b60f { // +x
            sstore(0xb, add(sload(0xb), 1))
        }
        // can do it by using the calldata length too
        default {
            if not(iszero(sload(0xe))) {
                sstore(0xe, sub(sload(0xe), 1))
                let calldatalen := calldatasize()
                if eq(calldatalen, 0x1) { 
                    sstore(0xc, sub(sload(0xc), 1)) // - y
                }
                if eq(calldatalen, 0x2) {
                    sstore(0xb, sub(sload(0xb), 1)) // - x
                }
                if eq(calldatalen, 0x3) {
                    sstore(0xc, add(sload(0xc), 1)) // + y 
                }
                if eq(calldatalen, 0x4) {
                    sstore(0xb, add(sload(0xb), 1)) // + x
                }
            }
        }
    ```

3. **Position Determination:**
  
    The `getPos` function in the Yul code calculates the sprite type at a given (x, y) coordinate in the maze. It works as follows:

   1. **Adjusts the x-coordinate** by calculating `10 - x` and multiplies the result by 8. This step finds the bit position of the sprite in the storage slot, considering each sprite occupies 8 bits (1 byte).

   2. **Retrieves the y-coordinate storage slot** using `sload(y)`, which loads the data stored at the y-coordinate.

   3. **Shifts the bits** to the right by the calculated bit position using `shr`. This isolates the 8-bit sprite data for the given x-coordinate.

   4. **Extracts the sprite type** using a bitwise AND with `0xff` to keep only the last 8 bits. This represents the sprite type (e.g., empty, wall, player) at the (x, y) location.

   ```solidity
        // Function restructured to logically align x and y
        function getPos(x, y) -> type_ {
            type_ := and(shr(mul(8, sub(10, x)), sload(y)), 0xff)
        }
   ```

4. **Gameplay Dynamics:**
   - The contract ensures the player remains within the maze's confines.
   - Hitting a wall or an invalid space results in a game over.
   - Reaching the exit (sprite type `0x3`) signifies the game is solved.
   ```solidity
        let pos_x := sload(0xb)
        let pos_y := sload(0xc)

        // check if player still in the maze
            if gt(pos_x, 10) {
                verbatim_0i_0o(hex"4e4f204553434150452046524f4d204d415a4521")
            }

            if gt(pos_y, 10) {
                verbatim_0i_0o(hex"5448495320495320412046414b4520464c4147")
            }

            let pos := getPos(pos_x, pos_y)

        // if player outside or on wall ==> dead
            if or(eq(pos, 0x1), eq(pos, 0xff)) {
                verbatim_0i_0o(hex"4556454e204d4152494f2043414e4e4f542048495420544849532057414c4c")
            }

        if eq(pos, 0x3) {
            verbatim_0i_0o(hex"6001600d5500")
        }
   ```

### Solving the Challenge

The initial step involves mapping a path through the maze. The chosen path for this write-up involves a series of movements altering `x` and `y` coordinates. Here's an illustration:

![Maze Path Visualization](util/Maze/mazePath.png)

Given the starting position at [0,0], the y-axis is inverted, and the x-axis behaves typically. The path :
```
- +y
- +x
- +y * 2
- +x * 2
- -y * 2
- +x * 2
- +y * 4
- +x * 4 
- +y * 2
- -x * 2
- +x * 3
```


Example transaction to trigger `+y` movement:
```solidity
// Setting PrivateKey and PublicKey 
uint256 py = uint8(bytes1(0x7a));
address PY_addr = vm.addr(py);

// Label the addr to debug efficiently in the foundry stacktrace
vm.label(PY_addr, "PY");

// Signe the next transaction with the PrivateKey given
vm.broadcast(py);
maze.call("");
```

Upon executing the script repeatedly to create a series of transactions, the script unexpectedly fails.

During the debugging process, it becomes apparent that the actions for `- y` and `+ y` have identical results. This anomaly is linked to a known issue described in [Solidity's documentation](https://soliditylang.org/blog/2023/11/08/verbatim-invalid-deduplication-bug/), where the optimizer mistakenly perceives both blocks of code as identical and merges them.

Initially, during the CTF, I wasn't aware of this optimizer issue and instead explored an alternative approach for adjusting the player's position using the default case in the `switch` statement. 

This is why this particular path was selected because the default mode can be accessed only twice, as it decrements the value in storage slot `0xe` (initialized with `0x02`) each time it's entered.

```solidity
// Player movement can also be controlled using calldata length
default {
    if not(iszero(sload(0xe))) {
        sstore(0xe, sub(sload(0xe), 1))
        let calldatalen := calldatasize()
        if eq(calldatalen, 0x1) {
            sstore(0xc, sub(sload(0xc), 1)) // - y
        }
        if eq(calldatalen, 0x2) {
            sstore(0xb, sub(sload(0xb), 1)) // - x
        }
        if eq(calldatalen, 0x3) {
            sstore(0xc, add(sload(0xc), 1)) // + y
        }
        if eq(calldatalen, 0x4) {
            sstore(0xb, add(sload(0xb), 1)) // + x
        }
    }
}
```

For the specific instances where the `y` value needs to be decreased, transactions are signed using the player's private key and include a single byte of calldata, as demonstrated below:

```solidity
vm.broadcast(player);
maze.call(hex"ff");
vm.broadcast(player);
maze.call(hex"ff");
```

### Solution Script and Acknowledgments

Access the solution script here: [Solve Script](util/Maze/Solve.s.sol)


![Thanks](util/img/giphy.gif)


<p align="center">
Feel free to pose your questions here: https://twitter.com/0x_m4k2
</p>
