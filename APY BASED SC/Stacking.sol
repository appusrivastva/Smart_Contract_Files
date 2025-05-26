//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Stacking {
    IERC20 public usdx;

    uint256 public minStakeAmount = 100;
    uint256 public maxStakeAmount = 10000;
    uint256 public APR = 1200; // 12% APR = 1200 basis points
    uint256 public BASIS_POINT = 10000;

    address public owner;
    uint256 public stakeCount;
    uint256 constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    struct User {
        uint256 id;
        uint256 stakedAmount;
        bool isUnstake;
        uint256 timeOfStaking;
        uint256 totalInterest;
        address user;
        bool isClaim;
        uint256 lockPeriod;
    }

    mapping(uint256 => User) public stakes;
    mapping(address => uint256[]) public userStakes;

    event staked(address indexed account, uint256 amount);
    event unstaked(address indexed account, uint256 stakeId, uint256 amount);

    constructor(address _usdx) {
        usdx = IERC20(_usdx);
        owner = msg.sender;
    }

    function stakeAmount(uint256 _amount, uint256 _lockPeriod) external {
        require(_amount >= minStakeAmount && _amount <= maxStakeAmount, "Invalid stake amount");
        require(
            _lockPeriod == 7 days || _lockPeriod == 30 days || _lockPeriod == 90 days,
            "Lock period must be 7, 30, or 90 days"
        );

        require(usdx.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        stakeCount++;
        stakes[stakeCount] = User({
            id: stakeCount,
            stakedAmount: _amount,
            isUnstake: false,
            timeOfStaking: block.timestamp,
            totalInterest: 0,
            user: msg.sender,
            isClaim: false,
            lockPeriod: _lockPeriod
        });

        userStakes[msg.sender].push(stakeCount);
        emit staked(msg.sender, _amount);
    }

    function unstake(uint256 _id) external {
        require(userStakes[msg.sender].length > 0, "No staking found");
        User storage s = stakes[_id];
        require(msg.sender == s.user, "Not your stake");
        require(!s.isUnstake, "Already unstaked");

        uint256 reward = 0;
        if (block.timestamp >= s.timeOfStaking + s.lockPeriod && !s.isClaim) {
            reward = calculateReward(_id);
            s.totalInterest += reward;
            s.isClaim = true;
        }

        s.isUnstake = true;
        usdx.transfer(msg.sender, s.stakedAmount + reward);
        emit unstaked(msg.sender, _id, s.stakedAmount + reward);
    }

    function calculateReward(uint256 stakeId) internal view returns (uint256) {
        User storage s = stakes[stakeId];
        uint256 timeElapsed = block.timestamp - s.timeOfStaking;
        return (s.stakedAmount * APR * timeElapsed) / (BASIS_POINT * SECONDS_IN_YEAR);
    }

    function claimInterest(uint256 stakeId) external {
        User storage s = stakes[stakeId];
        require(msg.sender == s.user, "Not your stake");
        require(!s.isClaim, "Already claimed");

        uint256 reward = calculateReward(stakeId);
        s.totalInterest += reward;
        s.isClaim = true;

        usdx.transfer(msg.sender, reward);
    }

    // Admin Functions
    function setAPR(uint256 _newAPR) external onlyOwner {
        APR = _newAPR;
    }

    function emergencyWithdrawTokens(address _to, uint256 _amount) external onlyOwner {
        usdx.transfer(_to, _amount);
    }

    function getUserStakes(address _user) external view returns (uint256[] memory) {
        return userStakes[_user];
    }
}
