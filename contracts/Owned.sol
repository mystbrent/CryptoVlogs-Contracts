pragma solidity ^0.5.0;

contract Owned {
  address owner;
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function changeOwner(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }
}