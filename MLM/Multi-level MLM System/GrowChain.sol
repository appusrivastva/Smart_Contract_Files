//SPDX-License-Identifier:GPL-3.0
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address receipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract GrowChain is ReentrancyGuard {
    IERC20 public GNT;
    address public admin;
    bool public pause;
    uint256 public REGISTRATION_FEE = 10 * 10**18;
    uint256[5] public levelPercentage = [40, 20, 15, 10, 5]; //90% distribute
    uint256 public maxReferralDepth = 5;

    //    all events
    event Registered(
        address indexed user,
        address indexed referrer,
        uint256 time
    );
    event IncomeDistributed(address indexed to, uint256 level, uint256 amount);
    event Withdraw(address indexed admin, uint256 amount);
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    event TokenUpdated(address indexed oldToken, address indexed newToken);

    struct User {
        address referrer;
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

    constructor(address _gntAddress) {
        GNT = IERC20(_gntAddress);
        admin = msg.sender;
    }

    modifier onlybyAdmin() {
        require(
            msg.sender == admin,
            "This action can be performed by the contract owner"
        );
        _;
    }
    modifier whenNotPaused() {
        require(
            !pause,
            "Contract is paused by admin so u can not perform anything in this contract!"
        );
        _;
    }

    function registration(address _referrer)
        external
        whenNotPaused
        nonReentrant
    {
        require(_referrer != address(0), "Invalid referrer address");

        require(
            users[_referrer].isRegistered,
            "This referral account is not registered!"
        );

        require(_referrer != msg.sender, "Cannot refer yourself");

        require(
            !users[msg.sender].isRegistered,
            "This account is already registered!"
        );

        require(
            GNT.transferFrom(msg.sender, address(this), REGISTRATION_FEE),
            "transfer failed"
        );

        User storage newUser = users[msg.sender];
        newUser.referrer = _referrer;
        newUser.isRegistered = true;
        newUser.registrationTime = block.timestamp;
        emit Registered(msg.sender, _referrer, block.timestamp);

        distributeReferralIncome(_referrer);
    }

    function distributeReferralIncome(address _referrer) internal {
        address upline = _referrer;

        for (
            uint256 i = 0;
            i < levelPercentage.length && i < maxReferralDepth;
            i++
        ) {
            if (upline == address(0)) {
                break;
            }

            uint256 reward = (REGISTRATION_FEE * levelPercentage[i]) / 100;
            require(GNT.transfer(upline, reward), "Reward transfer failed");

            emit IncomeDistributed(upline, i + 1, reward);

            if (i == 0) {
                users[upline].directReferralIncome += reward;

                users[upline].directReferrals.push(msg.sender);
                users[upline].referralCount++;
            } else {
                users[upline].teamIncome += reward;
                users[upline].indirectReferrals.push(msg.sender);
            }
            users[upline].teamSize++;

            // update upline

            upline = users[upline].referrer;
        }
    }

    function getUserDetails(address _user)
        external
        view
        returns (
            address referrer,
            uint256 directReferralIncome,
            uint256 referralCount,
            uint256 teamIncome,
            uint256 teamSize,
            bool isRegistered,
            uint256 registrationTime
        )
    {
        User storage user = users[_user];
        return (
            user.referrer,
            user.directReferralIncome,
            user.referralCount,
            user.teamIncome,
            user.teamSize,
            user.isRegistered,
            user.registrationTime
        );
    }

    // function getDirectReferrals(address _user)
    //     external
    //     view
    //     returns (address[] memory)
    // {
    //     return users[_user].directReferrals;
    // }
    // pagination is added -> avoid loading too many addresses
    //  at once.->storage bloat and gas inefficiency over time   

    // start =10 limit =5 
    // end=start+limit=15  

    // size=15-10=5 

    function getDirectReferralsPaginated(address _user, uint256 start, uint256 limit)
    external
    view
    returns (address[] memory)
{
    address[] storage all = users[_user].directReferrals;
    uint256 end = start + limit;
    if (end > all.length) end = all.length;
    

    // result -> address=> size=end-start  
    address[] memory result = new address[](end - start);
    for (uint256 i = start; i < end; i++) {
        result[i - start] = all[i];
    }
    return result;
}

    function getIndirectReferrals(address _user)
        external
        view
        returns (address[] memory)
    {
        return users[_user].indirectReferrals;
    }

    // only admin can call this functions
    function changeRegistrationFee(uint256 _percentage) external onlybyAdmin {
        require(_percentage < 99, "invalid percentage");
        REGISTRATION_FEE = _percentage * 10**18;
    }

    function paused() external onlybyAdmin {
        pause = true;
    }

    function unpaused() external onlybyAdmin {
        pause = false;
    }

    // withdraw token by owner
    function withdraw(uint256 amount) external nonReentrant onlybyAdmin {
        GNT.transfer(admin, amount);
        emit Withdraw(admin, amount);
    }

    //transfer ownership

    function transferOwnership(address _newOwner) external onlybyAdmin {
        require(_newOwner != address(0), "Invalid new owner");
        address oldowner = admin;
        admin = _newOwner;
        emit OwnershipTransferred(oldowner, _newOwner);
    }

    // Update GLT Token Address (in case token address changes)

    function updateTokenAddress(address _token) external onlybyAdmin {
        require(_token != address(0), "invalid new bst");
        GNT = IERC20(_token);
    }

    function contractTokenBalance() external view returns (uint256) {
        return GNT.balanceOf(address(this));
    }
}
