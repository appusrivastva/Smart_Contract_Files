//SPDX-License-Identifier:GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NLNT is ERC20 {
    constructor() ERC20("NEOLIN TOKEN", "NLNT") {
        _mint(msg.sender, 100000000 * 1e18); // max supply
    }
}


//max supply-> 1000 lakh

