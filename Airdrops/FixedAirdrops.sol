//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract FixedAirdrops {
    // ERC20 token address
    IERC20 public token;
    // Owner/admin who can execute the airdrop

    address public owner;

    constructor(address _token) {
        owner = msg.sender;
        token=IERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not allowed");
        _;
    }

    
//    owner=> provides address + amount list.-> variable airdeop
// fixed airdrop=> owner fix amount for all  owner

    function sendAirDrop(address[] memory _recipient, uint256 amount)
        external
        onlyOwner
    {
        require(_recipient.length > 0, "no address provided");

        for (uint256 i = 0; i < _recipient.length; i++) {
            token.transfer(_recipient[i], amount);
        }
    }

}
