// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Challenge.sol";

contract ExploitScript is Script {
    Challenge chall = Challenge(0xd120465D26e07971249e84acc33178747Bb6437B);
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        bytes memory data = hex"66757a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a6c616e64";
        Jambo(address(chall.target())).answer{value : 1.1 ether}(data);
        
        vm.stopBroadcast();
    }
}