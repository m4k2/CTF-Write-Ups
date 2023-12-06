// Decompiled by library.dedaub.com
// 2023.12.02 05:59 UTC
// Compiled using the solidity compiler version 0.8.22


// Data structures and variables inferred from the use of storage instructions
uint256 _questionId; // STORAGE[0x0] 0x1337
uint256 stor_1; // STORAGE[0x1] keccak256(0x66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64)



function 0x149(bytes varg0, uint256 varg1) private { // SET FMP
    v0 = varg0 + (varg1 + 31 & ~0x1f);
    require(!((v0 > uint64.max) | (v0 < varg0)), Panic(65)); // failed memory allocation (too much memory)
    MEM[64] = v0;
    return ;
}

function revokeOwnership() public nonPayable { 
    0xa5(4, msg.data.length);
    0x149(MEM[64], 52);
    v0 = 0x501(1);
    require(STORAGE[keccak256(msg.sender)] == v0);
    STORAGE[keccak256(msg.sender)] = 0;
    return ;
}

function 0x501(uint256 varg0) private { 
    return varg0;
}

function 0x2f484947(bytes varg0) public payable { 
    //require(msg.data.length - 4 >= 32);
    require(varg0 <= uint64.max);
    require(4 + varg0 + 31 < msg.data.length);
    //require(varg0.length <= uint64.max, Panic(65)); // failed memory allocation (too much memory)
    v0 = new bytes[](varg0.length);
    0x149(v0, (varg0.length + 31 & ~0x1f) + 32); //@audit set fmp 
    //require(varg0.data + varg0.length <= msg.data.length); // ????
    CALLDATACOPY(v0.data, varg0.data, varg0.length); //@audit-info put varg0 in memory 
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
        if (!v7.balance) { // Decompilatin error
            v8 = 2300;
        }
        v11 = v6.call().value(v7.balance).gas(v8); //@audit here
        require(v11, MEM[64], RETURNDATASIZE()); //require success
        require(msg.sender.code.size == 0); // require msg.sender == not SC
    }
    return ;
}

function 0x617(address varg0) private { 
    return varg0;
}

function questionId() public nonPayable { 
    0xa5(4, msg.data.length);
    return _questionId;
}

function start(uint256 tokenId, bytes32 spellHash) public payable { 
    require(msg.data.length - 4 >= 64);
    //require(tokenId == tokenId);
    //require(spellHash == spellHash);
    if ((keccak256(msg.sender) >> 248) - 55) {
        _questionId = tokenId;
        0x149(MEM[64], 64);
        stor_1 = uint256(keccak256(spellHash));
        0x149(MEM[64], 52);
        v0 = 0x501(1);
        require(STORAGE[keccak256(msg.sender)] == v0); // require mapping(msg.sender) ==> TRUE, check if owner or deployer tmtc
    }
    return ;
}

function function_selector() public payable { 
    revert();
}

function 0xa5(uint256 varg0, uint256 varg1) private { 
    require(varg1 - varg0 >= 0);
    return ;
}

// Note: The function selector is not present in the original solidity code.
// However, we display it for the sake of completeness.

function function_selector( function_selector) public payable { 
    MEM[64] = 128;
    if (msg.data.length >= 4) {
        if (function_selector >> 224 == 0x2b968958) {
            revokeOwnership();
        } else if (function_selector >> 224 == 0x2f484947) {
            0x2f484947();
        } else if (function_selector >> 224 == 0xb06a5c52) {
            questionId();
        } else if (function_selector >> 224 == 0xf5b938e2) {
            start(uint256,bytes32);
        }
    }
    ();
}
