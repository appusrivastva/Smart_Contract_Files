//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address receipient, uint256 amount)
        external
        returns (bool success);

    function transferFrom(
        address sender,
        address receipient,
        uint256 amount
    ) external returns (bool success);
}

// 2 level MLM  registration with referral rewards paid in LLT tokens
// A -> B and C
//  B-> D E F
//  C-> G

//  A -> team size=6  -> total user who join using your direct referral and indirect referral
// A-> total team income -> direct referral and indirect referral -> Income

//  G jb join krta h toh  level 1 income-> level 1st h ->40%
// 20% A ko milega

contract LevelLink is ReentrancyGuard {
    IERC20 public LLT;
    address public owner;
    bool public pause;
    uint256 public REGISTRATION_FEE = 10 * 10**18;

    constructor(address _lltAddress) {
        LLT = IERC20(_lltAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    modifier whenNotPaused() {
        require(!pause, "ChainBoost is Paused");
        _;
    }

    struct User {
        address referrer; //address of referral
        uint256 directReferralIncome; //total direct referralIncome
        bool isRegistered; //user -> already register-> true
        uint256 referralCount; // total direct referralCount
        uint256 registrationTime; //time of registration
        address[] directReferrals; //address of all my referral
        uint256 teamIncome; //team income
        uint256 teamSize;
        address[] indirectReferrals;
    }
    mapping(address => User) public users;

    function registration(address _referrer)
        external
        nonReentrant
        whenNotPaused
    {
        require(_referrer != msg.sender, "Cannot refer yourself");

        require(!users[msg.sender].isRegistered, "Already registered");
        require(_referrer != address(0), "invalid referral");

        require(
            users[_referrer].isRegistered,
            "Referral user did not complete any registration "
        );

        require(
            LLT.transferFrom(msg.sender, address(this), REGISTRATION_FEE),
            "registration failed"
        );
        User storage currentReferrer = users[_referrer];

        // distribute 40% to direct refferal
        // calculate reward and send to referrer address
        uint256 reward = calculateDirectReferralReward(REGISTRATION_FEE);
        LLT.transfer(_referrer, reward);

        // distribute 20% to level 2 referral
        // cal reward and send to referral address of my referral Address
        if (currentReferrer.referrer != address(0)) {
            uint256 level2Reward = calculateLevel2ReferralReward(
                REGISTRATION_FEE
            );
            LLT.transfer(currentReferrer.referrer, level2Reward);
            //  updating team size teamIncome and also indirect referral
            User storage grandReferrer = users[currentReferrer.referrer];
            grandReferrer.indirectReferrals.push(msg.sender);
            grandReferrer.teamSize += 1;
            grandReferrer.teamIncome += level2Reward;
        }

        // update values
        users[_referrer].directReferralIncome += reward;
        users[_referrer].referralCount += 1;
        users[_referrer].teamSize += 1;
        users[_referrer].directReferrals.push(msg.sender);

        users[msg.sender].referrer = _referrer;
        users[msg.sender].isRegistered = true;
        users[msg.sender].registrationTime = block.timestamp;
        // directReferrals array is empty by default
    }

    //  distribute level2 income

    function calculateLevel2ReferralReward(uint256 _amount)
        internal
        pure
        returns (uint256 _amountReward)
    {
        return (_amount * 20) / 100;
    }

    function calculateDirectReferralReward(uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (amount * 40) / 100;
    }

    // total income is that -> all indirect referrals -> income and  direct referral-> income
    

    function getTotalIncome(address _user) public view returns (uint256) {
        User storage u = users[_user];
        return u.directReferralIncome + u.teamIncome;
    }

    function changeRegsiterationFee(uint256 _percentage) external onlyOwner {
        require(_percentage < 99, "invalid percentage");
        REGISTRATION_FEE = _percentage * 10**18;
    }

    function paused() external onlyOwner {
        pause = true;
    }

    function unpaused() external onlyOwner {
        pause = false;
    }
    

    // withdraw token by owner
    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        LLT.transfer(owner, amount);
    }

    //transfer ownership

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");
        owner = _newOwner;
    }

    //  Get All Direct Referrals of a User
    function getDirectReferrals(address _user)
        external
        view
        returns (address[] memory)
    {
        return users[_user].directReferrals;
    }

    // Get Basic Info of a User

    function getBasicInfoUser(address user)
        external
        view
        returns (
            address referrer,
            uint256 referralIncome,
            bool isRegistered,
            uint256 referralCount,
            uint256 registrationTime,
            uint256 teamIncome,
            uint256 teamSize
        )
    {
        User storage u = users[user];
        return (
            u.referrer,
            u.directReferralIncome,
            u.isRegistered,
            u.referralCount,
            u.registrationTime,
            u.teamIncome,
            u.teamSize
        );
    }

    // get total team size present only at level 2

    function getTotalTeamSize(address _user) external view returns (uint256) {
        User storage u = users[_user];
        return u.directReferrals.length + u.indirectReferrals.length;
    }

    // get all my indirect  referral->[]
    function getIndirectReferrals(address _user)
        external
        view
        returns (address[] memory)
    {
        return users[_user].indirectReferrals;
    }

    // Update BST Token Address (in case token address changes)

    function updateLLTAddress(address _token) external onlyOwner {
        require(_token != address(0), "invalid new bst");
        LLT = IERC20(_token);
    }
    
}
