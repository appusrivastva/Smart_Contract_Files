//SPDX-License-Identifier: GPL-3.0
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
    uint256[5] public levelPercentage = [40, 20, 15, 10, 5];
    uint256 public maxReferralDepth = 5;

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
        uint256 directReferralIncome;
        bool isRegistered;
        uint256 referralCount;
        uint256 registrationTime;
        address[] directReferrals;
        uint256 teamIncome;
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
        require(!pause, "Contract is paused by admin");
        _;
    }

    /**
     * @notice Register a new user under a valid referrer
     * @param _referrer Address of the referrer (must be already registered)
     */
    function registration(address _referrer)
        external
        whenNotPaused
        nonReentrant
    {
        require(_referrer != address(0), "Invalid referrer address");
        require(users[_referrer].isRegistered, "Referrer is not registered");
        require(_referrer != msg.sender, "Cannot refer yourself");
        require(!users[msg.sender].isRegistered, "Already registered");

        require(
            GNT.transferFrom(msg.sender, address(this), REGISTRATION_FEE),
            "Transfer failed"
        );

        User storage newUser = users[msg.sender];
        newUser.referrer = _referrer;
        newUser.isRegistered = true;
        newUser.registrationTime = block.timestamp;

        emit Registered(msg.sender, _referrer, block.timestamp);
        distributeReferralIncome(_referrer);
    }

    /**
     * @notice Get user details
     * @param _user Address of the user
     * @return referrer Referrer address
     * @return directReferralIncome Total direct referral income
     * @return referralCount Total direct referrals
     * @return teamIncome Total income from team
     * @return teamSize Total size of team (all levels)
     * @return isRegistered If the user is registered
     * @return registrationTime Timestamp of registration
     */
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

    /**
     * @notice Returns a paginated list of direct referrals
     * @param _user Address of the user
     * @param start Starting index
     * @param limit Number of addresses to return
     * @return Array of referral addresses
     */
    function getDirectReferralsPaginated(
        address _user,
        uint256 start,
        uint256 limit
    ) external view returns (address[] memory) {
        address[] storage all = users[_user].directReferrals;
        uint256 end = start + limit;
        if (end > all.length) end = all.length;

        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = all[i];
        }
        return result;
    }

    /**
     * @notice Get list of indirect referrals
     * @param _user Address of the user
     * @return Array of indirect referral addresses
     */
    function getIndirectReferrals(address _user)
        external
        view
        returns (address[] memory)
    {
        return users[_user].indirectReferrals;
    }

    /**
     * @notice Change the registration fee (only owner)
     * @param _percentage New fee in whole numbers (e.g., 10 means 10 tokens)
     */
    function changeRegistrationFee(uint256 _percentage) external onlybyAdmin {
        require(_percentage < 99, "Invalid percentage");
        REGISTRATION_FEE = _percentage * 10**18;
    }

    /**
     * @notice Pause the contract (only owner)
     */
    function paused() external onlybyAdmin {
        pause = true;
    }

    /**
     * @notice Unpause the contract (only owner)
     */
    function unpaused() external onlybyAdmin {
        pause = false;
    }

    /**
     * @notice Withdraw GNT tokens from contract (only owner)
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant onlybyAdmin {
        GNT.transfer(admin, amount);
        emit Withdraw(admin, amount);
    }

    /**
     * @notice Transfer contract ownership to a new address
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlybyAdmin {
        require(_newOwner != address(0), "Invalid new owner");
        address oldowner = admin;
        admin = _newOwner;
        emit OwnershipTransferred(oldowner, _newOwner);
    }

    /**
     * @notice Update the GNT token address (only owner)
     * @param _token New token contract address
     */
    function updateTokenAddress(address _token) external onlybyAdmin {
        require(_token != address(0), "Invalid token address");
        GNT = IERC20(_token);
        emit TokenUpdated(address(GNT), _token);
    }

    /**
     * @notice View the contract's GNT token balance
     * @return GNT balance held by the contract
     */
    function contractTokenBalance() external view returns (uint256) {
        return GNT.balanceOf(address(this));
    }

    // Internal logic (no NatSpec needed for private/internal functions)
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
                users[upline].indirectReferrals.push(upline);
            }
            users[upline].teamSize++;
            upline = users[upline].referrer;
        }
    }
}

// NatSpec documentation-> all public and external functions. NatSpec (Ethereum Natural Specification Format)
