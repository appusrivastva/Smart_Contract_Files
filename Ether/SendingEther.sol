//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;

//there are 3 methods to sending ether

// transfer, send ,call

// send->bool val if txn failed a-> all gas used no refund -> doesn't revert automatically
// transfer-> revert automatically and gas fee refund-> 
// call-> return bool and byte data


contract SendEther{
    address payable  recipient=payable (0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    function sendEth(address payable  _recipient) public payable {
        _recipient.transfer(1 ether);
    }


    function sendEther() public  payable {
        bool sent=recipient.send(1 ether);
        require(sent,"failed");
    }

    // call is prefered for sending ether

    function sendEthbyCall() public  payable {
        (bool success,)=recipient.call{value:1 ether}("");
        require(success,"failed");

    }

}