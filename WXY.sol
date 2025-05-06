
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
contract Wxy is ERC20 {
    constructor(uint256 initialSupply) ERC20("W-XY", "WXY") {
        _mint(msg.sender, initialSupply);
    }
}
 
