//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;


contract A{
    function charA() public  pure virtual returns (string memory){
        return  "A";
    }
}


contract B is A{
    function charA() public pure virtual  override returns (string memory) {
        return "B";
    }
}