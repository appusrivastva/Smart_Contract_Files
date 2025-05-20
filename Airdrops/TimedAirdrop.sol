//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract ClaimAirdeops {
    // Airdrop should run from May 21, 2025 – May 25, 2025.
    uint256 startTime; //21 may
    uint256 endTime; //25 may
    IERC20 public token;
    address public owner;
    bool public  pause;
    mapping(address => uint256) public airdropAmount;
    mapping(address => bool) public hasClaimed;

    constructor(
        address _tokenAddress,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(
            _endTime >= startTime,
            "end time should be greater than startTime"
        );
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier  whenNotPaused(){
        require(!pause,"airdrop  is paused");
        _;
    }
  

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier withinClaimPeriod() {
        require(block.timestamp >= startTime, "claim period is not started");
        require(block.timestamp <= endTime, "claim period ended");
        _;
    }

    //owner set airdrop amount to list of user
    function setAirdropamount(
        address[] calldata receipient,
        uint256[] calldata amount
    ) external onlyOwner {
        require(receipient.length == amount.length, "missing input");
        for (uint256 i = 0; i < receipient.length; i++) {
            token.transfer(receipient[i], amount[i]);
        }
    }

    // Users claim their tokens manually.
    //  claimable Airdrop (Open Claim)

    //  store eligibility in the contract.

    function claim() external withinClaimPeriod whenNotPaused{
        require(!hasClaimed[msg.sender], "already claimed");
        uint256 amount = airdropAmount[msg.sender];
        require(amount > 0, "No Airdrops");
        hasClaimed[msg.sender] = true;

        token.transfer(msg.sender, amount);
    }

    // admin can update starttime and endtime 

    function updateClaimPeriod(uint _startTime,uint _endTime) external  onlyOwner{
        require(_endTime>=_startTime,"endTime cannot be less than start time");
        startTime=_startTime;
        endTime=_endTime;
    }


    // if anythis goes wrong we can stop airdrop

    function paused() external  onlyOwner{
        pause = true;
    }
    
    function unpaused() external   onlyOwner {
        pause = false;
    }


}
