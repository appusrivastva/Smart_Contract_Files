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

    function burn(address from, uint256 amount) external {
    require(msg.sender == pool, "Only pool can burn");
    _burn(from, amount);
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
    uint public  feePercentage=3;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken(); // deploy LP token
        owner = msg.sender;
    }

    // slipage set which is 5 -> 5%
    function setSlipage(uint256 _expectedSlipage) public onlyOwner {
        require(_expectedSlipage > 0, "invalid slippage");
        expextedSlippage = _expectedSlipage;
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

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

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
        uint256 fee = (amountIn * feePercentage) / 100;
        uint256 amountInAfterFee = amountIn - fee;
        require(expectSlippage > checkSlippage(amountInAfterFee), "actual slippage is too high");


        uint256 newReserveA = reserveA + amountInAfterFee;
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
        uint256 fee = (amountIn * feePercentage) / 100;
        uint256 amountInAfterFee = amountIn - fee;
        require(expectSlippage > checkSlippageB(amountInAfterFee), "actual slippage is too high");


        uint256 newReserveB = reserveB + amountInAfterFee;
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
    function getReserves() public view returns (uint256, uint256) {
    return (reserveA, reserveB);
}


    function getExpectedTokenB(uint256 amountIn) public view returns (uint256 expectedOut) {
        require(amountIn > 0, "Invalid amount");

        require(reserveB > 0, "Insufficient liquidity");
        uint256 ratio = (reserveA * 1e18) / reserveB;

        expectedOut = (amountIn * 1e18) / ratio;
        return expectedOut;
    }

    function getExpectedTokenA(uint256 amountIn) public view returns (uint256 expectedOut) {
        require(amountIn > 0, "Invalid amount");

        require(reserveA > 0, "Insufficient liquidity");
        uint256 ratio = (reserveB * 1e18) / reserveA;

        expectedOut = (amountIn * 1e18) / ratio;
        return expectedOut;
    }


    //remove liquidity 
    function removeLiquidity(uint256 liquidity) public {
    require(liquidity > 0, "Invalid liquidity amount");
    require(lpToken.balanceOf(msg.sender) >= liquidity, "Not enough LP tokens");

    uint256 totalSupply = lpToken.totalSupply();

    // Calculate the amount of Token A and Token B to return
    uint256 amountA = (liquidity * reserveA) / totalSupply;
    uint256 amountB = (liquidity * reserveB) / totalSupply;

    require(amountA > 0 && amountB > 0, "Insufficient amount to withdraw");

    // // Burn LP tokens
    // lpToken.transferFrom(msg.sender, address(this), liquidity);
    // lpToken.mint(address(0), liquidity); // effectively burns LP tokens (minting to 0 address)

    lpToken.burn(msg.sender, liquidity);

    

    // Update reserves
    reserveA -= amountA;
    reserveB -= amountB;

    // Transfer tokens back to the user
    require(tokenA.transfer(msg.sender, amountA), "Token A transfer failed");
    require(tokenB.transfer(msg.sender, amountB), "Token B transfer failed");
}

    function getUserLPBalance(address user) public view returns (uint256) {
    return lpToken.balanceOf(user);
}
function getLPTokenAddress() public view returns (address) {
    return address(lpToken);
}


}
