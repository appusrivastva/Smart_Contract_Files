//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;

// contract Logic{
//     uint public  num;

//     function setNum(uint n) public  {
//         num=n;
//     }
// }
//  use delegatecall when you want use logic of different contract in your contract
//  if u use delegatecall in your contract then u have same state variable which already prense in  the target contract have
// contract Proxy{
//     uint public  num;
//     address public  logicAddress;
//     constructor(address _logicAddress){
//         logicAddress=_logicAddress;
//     }

//    function setLogic(address _newLogic) public {
//       logicAddress=_newLogic;
//    }
//     function setNum(uint n) public {
//         (bool success,) =logicAddress.delegatecall(abi.encodeWithSignature("setNum(uint256)",n));
//         require(success,"failed");
        
//     }
// }


// delegate call vs call

contract A {
    uint public num;

    function setNum(uint _num) public {
        num = _num;
    }
}

contract B {
    uint public num;

    address public logic;

    constructor(address _logic) {
        logic = _logic;
    }

    function callSetNum(uint _num) public {
        // Normal call
        (bool success, ) = logic.call(abi.encodeWithSignature("setNum(uint256)", _num));
        require(success);
    }

    function delegateSetNum(uint _num) public {
        // Delegate call
        (bool success, ) = logic.delegatecall(abi.encodeWithSignature("setNum(uint256)", _num));
        require(success);
    }
}
// when u use call then  it change the logic state variable-> target address contract-> state variable
// when u use delegatecall -> it change caller state variable
