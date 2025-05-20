//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract ClaimAirdeops {
    IERC20 public token;
    address public owner;
    mapping(address => uint256) public airdropAmount;
    mapping(address => bool) public hasClaimed;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


//owner set airdrop amount to list of user
    function setAirdropamount(
        address[] calldata receipient,
        uint256[] calldata amount
    ) external onlyOwner {
        require(receipient.length==amount.length,"missing input");
        for(uint i=0;i<receipient.length;i++){
            token.transfer(receipient[i], amount[i]);
        }

    }

      // Users claim their tokens manually.
        //  claimable Airdrop (Open Claim)


    //  store eligibility in the contract.

      function claim() external {
        require(!hasClaimed[msg.sender],"already claimed");
        uint amount=airdropAmount[msg.sender];
        require(amount>0, "No Airdrops");
        hasClaimed[msg.sender]=true;
    
        token.transfer(msg.sender,amount );
      }
  
  



     
}
