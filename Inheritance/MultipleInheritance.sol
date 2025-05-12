//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;

contract A{
    function getNum() public   pure virtual  returns(uint){
        return  1;
    }
}

contract B is A{
    function getNum() public  pure  virtual  override  returns (uint){
        return  2;
    }
}
contract C is A{
    function getNum() public virtual   pure override  returns (uint){
        return  3;
    }
}

//multiple inheritane perform and c3 liniearization -> right to left 

//  D  -> C -> A -> B   

//  super.getNum() call-> getNum b and c both parent me h but  call hoga nearest right me h d ke c h toh iska getNum() execute 
contract D is B,C{
   function getNum() public  pure virtual  override(B,C)   returns(uint)
   {
    return  super.getNum();
}
}
