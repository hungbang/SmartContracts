pragma solidity ^0.4.4;

import "Configurable.sol";
import "./zeppelin/ownership/Shareable.sol";
import "LibCLLi.sol";

contract Managed is Configurable, Shareable {

  uint constant HEAD = 0; // Lists are circular with static head.
  bool constant PREV = false;
  bool constant NEXT = true;
  uint constant MAXNUM = uint(-1); // 2**256 - 1
    
  // Allows us to use library functions as if they were members of the type.
  using LibCLLi for LibCLLi.CLL;

  // The circular linked list state variable.
  LibCLLi.CLL list;

  enum Operations {createLOC,editLOC,LOCstatus}
  address[] own;
  mapping (bytes32 => Transaction) txs;
  uint numAuthorizedKeys = 1;

  struct Transaction {
    address to;
    bytes data;
    Operations op;
    bool confirmed;
  }

  function Managed() Shareable(own,required) {
    required = 2;
    address owner  = msg.sender;
    owners[numAuthorizedKeys] = uint(owner);
    ownerIndex[uint(owner)] = numAuthorizedKeys;
    numAuthorizedKeys++;
  }

  function setRequired(uint _required) onlyAuthorized() {
    required = _required; 
  }

  modifier onlyAuthorized() {
      if (isAuthorized(msg.sender)) {
          _;
      }
  }

  modifier execute(Operations _type) {
   if(numAuthorizedKeys > 2) {
   if (this != msg.sender) {
      bytes32 _r = sha3(msg.data,"signature");
      txs[_r].data = msg.data;
      txs[_r].op = _type;
      txs[_r].to = this;
      confirm(_r);
    } 
    else {
     _;
    }
  } else {
  _;
  }
 }

  function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
     if (txs[_h].to != 0) {
      if(!txs[_h].to.call(txs[_h].data)) {
        throw;
      }
      return true;
      }
  }
  
  function isAuthorized(address key) returns(bool) {
      if(ownerIndex[uint(key)] != uint(0x0)) {
        return true;
      }
      return false;
  } 

  function addKey(address key) execute(Operations.createLOC) {
    if (ownerIndex[uint(key)] == uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      owners[numAuthorizedKeys] = uint(key);        
      ownerIndex[uint(key)] = numAuthorizedKeys;
      numAuthorizedKeys++;
    }
  }

  function revokeKey(address key) execute(Operations.createLOC) {
    if (ownerIndex[uint(key)] != uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      ownerIndex[uint(key)] = 0;
      numAuthorizedKeys--;
    }
  }

}