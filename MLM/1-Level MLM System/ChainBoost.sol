//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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

// a basic 1-level MLM registration with referral rewards paid in BST tokens.


contract ChainBoost {
      IERC20 public BST;
    address public owner;
    bool public  pause;

    uint256 public  REGISTRATION_FEE = 10 * 10**18; //10 bst per registration

    constructor(address _bstAddress) {
        BST = IERC20(_bstAddress);
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }
    modifier  whenNotPaused{
        require(!pause, "ChainBoost is Paused");
        _;
    }

    struct User {
        address referrer; //address of referral
        uint256 referralIncome; //total direct referralIncome
        bool isRegistered; //user -> already register-> true
        uint256 referralCount; // total direct referralCount
        uint256 registrationTime; //time of registration
        address[] directReferrals; //address of all my referral
    }
    mapping(address => User) public users;

    function registration(address _referrer) external whenNotPaused{
        require(!users[msg.sender].isRegistered, "Already registered");
        require(_referrer != address(0), "invalid referral");

        require(
            users[_referrer].isRegistered,
            "Referral user did not complete any registration "
        );

        require(
            BST.transferFrom(msg.sender, address(this), REGISTRATION_FEE),
            "registration failed"
        );

        // distribute 40% to direct refferal
        // calculate reward and send to referrer address
        uint256 reward = calculateDirectReferralReward(REGISTRATION_FEE);
        BST.transfer(_referrer, reward);

        // update values
        users[_referrer].referralIncome += reward;
        users[_referrer].referralCount += 1;
        users[_referrer].directReferrals.push(msg.sender);

        users[msg.sender].referrer = _referrer;
        users[msg.sender].referralIncome = 0;
        users[msg.sender].isRegistered = true;
        users[msg.sender].referralCount = 0;
        users[msg.sender].registrationTime = block.timestamp;
        // directReferrals array is empty by default

        // Remaining 60% stays in contract or later withdrawn by admin
    }

    function calculateDirectReferralReward(uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (amount * 40) / 100;
    }

    function changeRegsiterationFee(uint _percentage) external  onlyOwner{
        require(_percentage < 99, "invalid percentage");
        REGISTRATION_FEE = _percentage*10**18;
    }

    function paused() external onlyOwner{
        pause=true;
    }
    function unpaused() external onlyOwner{
        pause=false;
    }

    // withdraw token by user
    function withdraw(uint amount) external onlyOwner{
        BST.transfer(owner, amount);
    }

    //transfer ownership

    function transferOwnership(address _newOwner) external onlyOwner{
        require(_newOwner != address(0), "Invalid new owner");
        owner = _newOwner;
    }

    //  Get All Direct Referrals of a User
    function getDirectReferrals(address _user ) external view returns(address[] memory){
          return users[_user].directReferrals;
    }
    

    // Get Basic Info of a User

    function getBasicInfoUser(address user) external view returns(address referrer, 
    uint referralIncome,bool isRegistered,uint referralCount,uint registrationTime) {
        User storage u=users[user];
        return (
            u.referrer,
            u.referralIncome,
            u.isRegistered,
            u.referralCount,
            u.registrationTime
        
        );
    }
    

    // Update BST Token Address (in case token address changes)

    function updateBSTAddress(address _token) external onlyOwner{
        require(_token != address(0), "invalid new bst");
        BST = IERC20(_token);
    }





    
}
