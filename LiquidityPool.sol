// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// LP Token Contract
contract LPToken is ERC20 {
    address public pool;

    constructor() ERC20("Liquidity Provider Token", "LPT") {
        pool = msg.sender; // Only Liquidity Pool can mint
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == pool, "Only pool can mint");
        _mint(to, amount);
    }
}

// Liquidity Pool Contract
contract LiquidityPool {
    IERC20 public tokenA;
    IERC20 public tokenB;
    LPToken public lpToken;

    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public expextedSlippage;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // slipage set which is 5 -> 5%
    function setSlipage(uint256 _expectedSlipage) public onlyOwner {
        require(_expectedSlipage > 0, "invalid slippage");
        expextedSlippage = _expectedSlipage;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken(); // deploy LP token
        owner = msg.sender;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) public returns (uint256 liquidity) {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        // Transfer tokens from user to this contract
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "TokenA transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "TokenB transfer failed");

        uint256 totalSupply = lpToken.totalSupply();

        if (totalSupply == 0) {
            // First LP
            liquidity = sqrt(amountA * amountB);
        } else {
            // Proportional LP token minting
            uint256 liquidityFromA = (amountA * totalSupply) / reserveA;
            uint256 liquidityFromB = (amountB * totalSupply) / reserveB;
            liquidity = min(liquidityFromA, liquidityFromB);
        }

        require(liquidity > 0, "Insufficient liquidity");

        // Mint LP tokens to user
        lpToken.mint(msg.sender, liquidity);

        // Update reserves
        reserveA += amountA;
        reserveB += amountB;
    }

    // Utility: Minimum of two values
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    // Utility: Square root using Babylonian method
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getPrice() public view returns (uint256) {
        require(reserveB > 0, "No liquidity");
        return (reserveA * 1e18) / reserveB;
    }

    // Swap A to B
    function swapAtoB(uint256 amountIn, uint256 expectSlippage) public returns (uint256) {
        require(amountIn > 0, "Invalid input amount");
        require(expextedSlippage > 0, "Expected slippage not set");
        require(expectSlippage > checkSlippage(amountIn), "actual slippage is too high");

        uint256 newReserveA = reserveA + amountIn;
        uint256 k = reserveA * reserveB;
        uint256 newReserveB = k / newReserveA;
        uint256 amountOut = reserveB - newReserveB;

        require(tokenA.transferFrom(msg.sender, address(this), amountIn), "Token A transfer failed");
        require(tokenB.transfer(msg.sender, amountOut), "Token B transfer failed");

        reserveA = newReserveA;
        reserveB = newReserveB;

        return amountOut;
    }

    // Swap B to A
    function swapBtoA(uint256 amountIn, uint256 expectSlippage) public returns (uint256) {
        require(amountIn > 0, "Invalid input amount");
        require(expextedSlippage > 0, "Expected slippage not set");
        require(expectSlippage > checkSlippageB(amountIn), "actual slippage is too high");

        uint256 newReserveB = reserveB + amountIn;
        uint256 k = reserveA * reserveB;
        uint256 newReserveA = k / newReserveB;
        uint256 amountOut = reserveA - newReserveA;

        require(tokenB.transferFrom(msg.sender, address(this), amountIn), "Token B transfer failed");
        require(tokenA.transfer(msg.sender, amountOut), "Token A transfer failed");

        reserveA = newReserveA;
        reserveB = newReserveB;

        return amountOut;
    }

    // Check slippage for A to B
    function checkSlippage(uint256 amountIn) public view returns (uint256) {
        require(amountIn > 0, "give correct value");

        uint256 expectAmount = getExpectedTokenB(amountIn);

        uint256 newReserveA = reserveA + amountIn;
        uint256 k = reserveA * reserveB;
        uint256 newReserveB = k / newReserveA;
        uint256 amountOut = reserveB - newReserveB;

        uint256 slippagePercent = 100 - ((amountOut * 100) / expectAmount);
        return slippagePercent;
    }

    // Check slippage for B to A
    function checkSlippageB(uint256 amountIn) public view returns (uint256) {
        require(amountIn > 0, "give correct value");

        uint256 expectAmount = getExpectedTokenA(amountIn);

        uint256 newReserveB = reserveB + amountIn;
        uint256 k = reserveA * reserveB;
        uint256 newReserveA = k / newReserveB;
        uint256 amountOut = reserveA - newReserveA;

        uint256 slippagePercent = 100 - ((amountOut * 100) / expectAmount);
        return slippagePercent;
    }

    // Get expected token B amount for a given amount of token A
    function getExpectedTokenB(uint256 amountIn) public view returns (uint256 expectedOut) {
        require(amountIn > 0, "Invalid amount");

        require(reserveB > 0, "Insufficient liquidity");
        uint256 ratio = (reserveA * 1e18) / reserveB;

        expectedOut = (amountIn * 1e18) / ratio;
        return expectedOut;
    }

    // Get expected token A amount for a given amount of token B
    function getExpectedTokenA(uint256 amountIn) public view returns (uint256 expectedOut) {
        require(amountIn > 0, "Invalid amount");

        require(reserveA > 0, "Insufficient liquidity");
        uint256 ratio = (reserveB * 1e18) / reserveA;

        expectedOut = (amountIn * 1e18) / ratio;
        return expectedOut;
    }
}
