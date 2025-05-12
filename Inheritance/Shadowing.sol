//SPDX-License-Identifier:GPL-3.0

pragma solidity >=0.7.0<0.9.0;


contract A{
    string public  name="APOORVA";

    function getName() public  view returns(string memory){
        return  name;
    }
}
//state variable declare in child contract with same name already present in parent contract 
//  conflict create or shadow or hide parent state varibale you are assuming that u are accessing parent state variable
// It's easy to mistakenly believe you're accessing or modifying the parent variable.

//  so u can use variable with another name
contract B is A{

    // string public  name="hi";

    constructor(){
        name="appu";
    }
    function get() public  view returns(string memory){
        return  name;
    }
}