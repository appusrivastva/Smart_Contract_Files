//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stacking {
    //erc20 token -> which is nlnt

    IERC20 public nlnt;

    //admin who deploy this contract
    address public admin;
    uint256 public constant cliff = 60 days;
    uint256 public constant totalDuration = 365 days;
    event tokenLock(address indexed _to, uint256 indexed _amount);
    event claimedToken(address indexed to, uint256 indexed amount);
    struct Lock {
        uint256 nlntAmount;
        uint256 start;
        uint256 cliffDuration;
        uint256 duration;
        uint256 claimAmount;
    }
    mapping(address => Lock) public allStackDetails;

    constructor(address _nlnt) {
        nlnt = IERC20(_nlnt);
        admin = msg.sender;
    }

    function lockToken(address _userAddress, uint256 _nlntAmount) external {
        require(msg.sender == admin, "NotAdmin, so you can't lock the token");
        //user ka alreday amount lock h

        require(allStackDetails[_userAddress].nlntAmount == 0, "already lock");
        nlnt.transferFrom(_userAddress, address(this), _nlntAmount);
        allStackDetails[_userAddress] = Lock(
            _nlntAmount,
            block.timestamp,
            cliff,
            totalDuration,
            0
        );
        emit tokenLock(_userAddress, _nlntAmount);
    }

    // function claimToken() external {
    //     require(allStackDetails[msg.sender].start != 0, "NotLocked");
    //     require(allStackDetails[msg.sender].nlntAmount > 0, "no token");
    //     Lock storage l = allStackDetails[msg.sender];
    //     require(
    //         l.start + cliff <= block.timestamp,
    //         "you have to wait atleast two month after locking the token"
    //     );
    //     uint256 _claimAmount = (l.nlntAmount * 1) / 100;
    //     //update
    //     l.claimAmount = _claimAmount;

    //     l.cliffDuration = 0;
    //     l.nlntAmount = l.nlntAmount - l.claimAmount;
    //     nlnt.transfer(msg.sender, _claimAmount);
    //     emit claimedToken(msg.sender, _claimAmount);
    // }

    function claimTokens() external {
        Lock storage l = allStackDetails[msg.sender];

        require(l.start != 0, "not locked token yet");
        require(l.nlntAmount > 0, "no token");
        require(
            block.timestamp >= (l.start + cliff),
            "it's time to claim tokens"
        );
        //    abhi  tk time kitna pass hua
        uint256 timePassed = block.timestamp - l.start;

        // agar timepassed jada hoga jo totalduration di h usse
        // jb token lock kra tbse ab tk ka time
        if (timePassed > totalDuration) {
            timePassed = totalDuration;
        }
        // cliff duration ke bad se time

        uint256 vestingTime = timePassed - cliff;

        // kitna month pass hua after cliff duration

        uint256 monthPass = vestingTime / 30 days;

        // monthpass-> 3 month
        // ab cliff ke bad usko jitne v month honge uske acc usko % milega uske token
        uint256 totalVasted = (l.nlntAmount * 10 * monthPass) / 100;
        // first time claimamount->0 hoga
        // second time claim krega toh  jitna totalvasted horha usme se claimamount minus krdenge jo ab second time vo claim krrha

        uint256 claimable = totalVasted - l.claimAmount;
        require(claimable > 0, "No tokens available to claim yet");
        //update

        l.claimAmount += claimable;
        nlnt.transfer(msg.sender, claimable);
        emit claimedToken(msg.sender, claimable);
    }
}

// token lock time->  1747217858

// cliff=5184000 secons -> 60day

// duration->  31556926

// token claim time->  1749896258

// time diff= start - claim time= 2678400

// timediff>= duration   totalvested -> alllock token
// timediff<= duration   totalvased=1% of alllocktoken
