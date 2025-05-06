// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./LiquidityPool.sol";

contract FactoryPool {
    mapping(address => mapping(address => address)) public getPairs;
    //tokenA=> tokenB => pool ka address

    address[] public allPools;
    address public owner;
    event PairCreated(address indexed tokenA, address indexed tokenB, address pair);

    constructor() {
        owner = msg.sender;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner, "you aren't owner");
        _;
    }

    function createPair(address tokenA, address tokenB)
        public
        returns (address)
    {
        //first we check  both tokens different
        require(tokenA != tokenB, "Identical Address");
        //now check this pair is't already exist

        require(
            getPairs[tokenA][tokenB] == address(0),
            "this pair is already exist"
        );
        //   pool create 
        LiquidityPool newPool = new LiquidityPool(tokenA, tokenB);

        //   after successfully pool creation

        address poolAddress = address(newPool);

        getPairs[tokenA][tokenB] = poolAddress;

        getPairs[tokenB][tokenA] = poolAddress;

        allPools.push(poolAddress);
        emit  PairCreated(tokenA, tokenB, poolAddress);
        return poolAddress;
    }



    function allPairsLength() external view returns (uint256) {
        return allPools.length;
    }







    

}
