//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;

// contract A{
//     function num() public pure  virtual returns (uint256){
//         return  1;
//     }
// }

// contract B is A{
//      function num() public pure   virtual override  returns (uint256){
//         return  2;
//     }

// }

// contract C is B{
//      function num() public pure  virtual override  returns (uint256){
//         return  3;
//     }

//     function getNum() public pure  returns(uint){
//         return super.num();
//     }

// }


//  multi level -> A-> B-> C

//  c ka parent b h then super.num()-> 2

contract A {
    function doSomething() public pure virtual returns(string memory) {
        return "A";
    }
}

contract B is A {
    function doSomething() public pure virtual override returns(string memory) {
        return string(abi.encodePacked(super.doSomething(), "  B"));
    }
}

contract C is A {
    function doSomething() public pure virtual override returns(string memory) {
        return string(abi.encodePacked(super.doSomething(), "  C"));
    }
}

contract D is B, C {
    function doSomething() public pure override(B, C) returns(string memory) {
        return string(abi.encodePacked(super.doSomething(), "  D"));
    }
}
