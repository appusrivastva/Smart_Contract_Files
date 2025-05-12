//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;
import "./SendingEther.sol";

contract ReceiveEther{
    receive() external payable { }
    fallback() external payable { }
    function getBal() public  view  returns(uint256){
        return  address(this).balance;
    }
}