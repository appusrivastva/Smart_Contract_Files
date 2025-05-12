//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;

interface IAnimal {
    function speak() external  view returns(string memory);
    
}

contract  Dog is IAnimal {
    function speak() public virtual view returns (string memory){
        return "Woof";
    }
}
contract  Cat {
    function speak() public virtual view returns (string memory){
        return "MeoW";
    }
}