//SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address receipient,
        uint256 amount
    ) external returns (bool);
}

contract ContestPool is ReentrancyGuard, Ownable {
    IERC20 public plt;
    event CreateContest(
        string indexed contestName,
        uint256 entryFee,
        uint256 maxParticipient,
        uint256 contestId,
        address creator
    );

    event joinContets(address indexed userAddress, uint256 contestId);
    event endContest(address indexed contestOwner, uint256 contestId);

    struct Contest {
        uint256 contestId;
        uint256 entryFee;
        uint256 maxParticipient;
        address creatorAddress;
        address[] allJoinUsers;
        mapping(address => bool) hasJoined;
        bool isActive;
        string constestName;
        uint256 startTime;
        uint256 endTime;
        string description;
        uint256 totalUsers;
        address winner;
        uint256 pricePool;
        uint256 totalDeposit;
        uint256 softcap;
        bool isDiscard;
        bool isRewardDistributed;
        mapping(address => bool) refunded;
    }

    uint256 public PLATEFORM_FEE = 2;
    //    id-> Contest struct
    mapping(uint256 => Contest) public contests;
    // one address-> multiple id
    mapping(address => uint256[]) public allContests;

    uint256 public totalContest = 0;

    // function to add contest create by anyone
    // pool create -> user join -> entry fee pay

    constructor(address _pltAddress) Ownable(msg.sender) {
        plt = IERC20(_pltAddress);
    }

    function createContest(
        uint256 _entryFee,
        uint256 _maxParticipient,
        string memory contestDesc,
        string memory name,
        uint256 _softCap
    ) external {
        totalContest++;
        Contest storage newContest = contests[totalContest];
        newContest.constestName = name;
        newContest.entryFee = _entryFee;
        newContest.maxParticipient = _maxParticipient;
        newContest.creatorAddress = msg.sender;
        newContest.startTime = block.timestamp;
        newContest.endTime = newContest.startTime + 6 * 60 * 60;
        newContest.isActive = true;
        newContest.description = contestDesc;
        allContests[msg.sender].push(totalContest);
        newContest.contestId = totalContest;
        newContest.softcap = _softCap;
        emit CreateContest(
            name,
            _entryFee,
            _maxParticipient,
            totalContest,
            msg.sender
        );
    }

    function joinContest(uint256 _contestId) external {
        require(contests[_contestId].isActive, "This Contest is not active");
        Contest storage contest = contests[_contestId];
        require(
            block.timestamp >= contest.startTime,
            "This Contest is not Started Yet"
        );
        require(block.timestamp <= contest.endTime, "This Contest is Over!");
        // no duplicate participation

        require(
            !contest.hasJoined[msg.sender],
            "You are already participating"
        );
        require(
            contest.totalUsers < contest.maxParticipient,
            "Maximum participent already we had"
        );

        // pay entry fee
        require(
            plt.transferFrom(msg.sender, address(this), contest.entryFee),
            "failed"
        );
        contest.totalUsers++;
        contest.hasJoined[msg.sender] = true;
        contest.allJoinUsers.push(msg.sender);
        contest.totalDeposit += contest.entryFee;
        emit joinContets(msg.sender, _contestId);
    }

    function calCulatePricePool(uint256 _contestID)
        internal
        view
        returns (uint256, uint256)
    {
        Contest storage contest = contests[_contestID];

        uint256 totalCollected = contest.totalUsers * contest.entryFee;
        uint256 plateformFee = (totalCollected * PLATEFORM_FEE) / 100;
        // uint256 pricePool = totalCollected - plateformFee;
        // contest.pricePool = pricePool;
        return (plateformFee, totalCollected - plateformFee);
    }

    function discardContest(uint256 _contestId) external nonReentrant {
        Contest storage contest = contests[_contestId];
        require(
            msg.sender == contest.creatorAddress,
            "Only creator can discard"
        );
        require(contest.isActive, "Contest is not active");
        require(block.timestamp > contest.endTime, "Contest is not over yet");
        require(contest.totalDeposit < contest.softcap, "Soft cap reached");

        contest.isActive = false;
        contest.isDiscard = true;

        // Refund all participants
        // for (uint256 i = 0; i < contest.allJoinUsers.length; i++) {
        //     address user = contest.allJoinUsers[i];
        //     plt.transfer(user, contest.entryFee);
        // }
    }

    function _endContest(uint256 _contestId) external nonReentrant {
        Contest storage contest = contests[_contestId];
        require(contest.isActive, "Contest is not active");
        require(msg.sender == contest.creatorAddress, "Not creator");
        require(!contest.isDiscard, "This Contest is discarded");
        require(block.timestamp > contest.endTime, "Contest not ended");
        require(
            contest.totalDeposit >= contest.softcap,
            "Soft cap not reached"
        );

        contest.isActive = false;
        (uint256 fee, uint256 rewardPool) = calCulatePricePool(_contestId);
        contest.pricePool = rewardPool;
        plt.transfer(owner(), fee);

        emit endContest(contest.creatorAddress, _contestId);
    }

    function claimRefund(uint256 _contestId) external nonReentrant {
        Contest storage contest = contests[_contestId];
        require(contest.isDiscard, "Contest not discarded");
        require(contest.hasJoined[msg.sender], "You did not join this contest");
        require(!contest.refunded[msg.sender], "Already refunded");

        contest.refunded[msg.sender] = true;
        require(plt.transfer(msg.sender, contest.entryFee), "Transfer failed");
    }

    function updatePlatformFee(uint256 _fee) external onlyOwner nonReentrant {
        require(_fee <= 10, "Too high");
        PLATEFORM_FEE = _fee;
    }

    function distributeReward(uint256 _contestId, address[] calldata _winner)
        external
        onlyOwner
    {
        Contest storage contest = contests[_contestId];
        require(contest.pricePool > 0, "Contest not ended or prize not set");
        require(!contest.isRewardDistributed, "Rewards already distributed");

        // Rank 1 winner-> 20% of pricePool
        uint256 rank1Reward = (contest.pricePool * 20) / 100;
        require(plt.transfer(_winner[0], rank1Reward));

        // rank2-rank5  -> total 4 person-> 10% of pricepool distribute
        uint256 reward = (contest.pricePool * 10) / 100;
        for (uint256 i = 1; i <= 4; i++) {
            require(plt.transfer(_winner[i], reward / 4));
        }
        uint256 remainingReward = (contest.pricePool * 5) / 100;
        for (uint256 i = 5; i <= 9; i++) {
            require(plt.transfer(_winner[i], remainingReward / 5));
        }

        contest.isRewardDistributed = true;
    }
}
