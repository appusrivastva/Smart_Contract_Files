//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
interface IERC20 {
    function transfer(address receipient,uint amount) external returns (bool success);
    function transferFrom(address sender,address receipient,uint amount) external returns (bool success); 
    
}

contract ChainBoost {
    // 1-Level MLM System
    IERC20 public  BST;
    address public owner;

    uint public  constant REGISTRATION_FEE=10*10**18;   //10 bst per registration  
    constructor(address _bstAddress) {
        BST=IERC20(_bstAddress);
        owner=msg.sender;
    }

    struct User{
        address referrer;  //address of referral
        uint referralIncome;  //total direct referralIncome
        bool isRegistered;   //user -> already register-> true
        uint referralCount;   // total direct referralCount
        uint registrationTime;  //time of registration
        address[] directReferrals; //address of all my referral

    }
    mapping (address => User ) public users;

    function  registration(address _referrer) external {
        require(!users[msg.sender].isRegistered,"Already registered");
        require(_referrer!=address(0),"invalid referral");


        require(users[_referrer].isRegistered,"Referral user did not complete any registration ");


        require(BST.transferFrom(msg.sender,address(this), REGISTRATION_FEE),"registration failed");


        // distribute 40% to direct refferal 
        // calculate reward and send to referrer address
        uint reward=calculateDirectReferralReward(REGISTRATION_FEE);
        BST.transfer(_referrer, reward);


        // update values
        users[_referrer].referralIncome+=reward;
        users[_referrer].referralCount+=1;
        users[_referrer].directReferrals.push(msg.sender);

        users[msg.sender]=User({
            referrer: _referrer,
            referralIncome : 0,
            isRegistered   :true,
            referralCount     :0,
            registrationTime  : block.timestamp,
            directReferrals : new address[](0)
        

        });
         // Remaining 60% stays in contract or later withdrawn by admin


    }

    function calculateDirectReferralReward(uint amount)  internal   pure returns(uint){
        return  (amount*40)/100;


    }
 
}
