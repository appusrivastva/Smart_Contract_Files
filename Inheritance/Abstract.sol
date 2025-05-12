//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;


abstract contract A{
    function sayHii() external pure virtual returns(string memory);
}


contract B is A{
    function sayHii() public override pure returns(string memory){
        return "hi";
    }
}

//  abstract contract me at least one function without body/ implementation and add many function with implementation

