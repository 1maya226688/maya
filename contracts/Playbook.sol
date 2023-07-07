// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract  WhiteList is Ownable {
    mapping (address => bool) public whiteListed;

    modifier isWhiteListed() {
        require(whiteListed[msg.sender], "not whitelisted");
        _;
    }

    function getWhiteListStatus(address _maker) external view returns (bool) {
        return whiteListed[_maker];
    }

    function addWhiteList (address _evilUser) public onlyOwner {
        whiteListed[_evilUser] = true;
        emit AddedWhiteList(_evilUser);
    }

    function removeWhiteList (address _clearedUser) public onlyOwner {
        whiteListed[_clearedUser] = false;
        emit RemovedWhiteList(_clearedUser);
    }

    event AddedWhiteList(address _user);

    event RemovedWhiteList(address _user);
}


contract Relation is WhiteList{
    mapping(address => address) mapUpperLevel;
    mapping(address => address[]) mapLowerLevel;
    mapping(address => uint256) mapLevelType;
    address public root;

    address[] public users;
    mapping(address => uint256) public mapUser;

    function SetUpperLevel(address _upperLevel,address _myaddr) public  isWhiteListed {
        require(GetmapLevelType(_upperLevel) > 0 ||  _upperLevel == root);
        require(msg.sender != _upperLevel, "You cannot set yourself");
        require(_upperLevel != address(0),"Cannot 0x0");
        if(_upperLevel == root) {
            mapLevelType[_myaddr] = 1;
            mapUpperLevel[_myaddr] = root;
            mapLowerLevel[root].push(_myaddr);
        }
        if(_upperLevel != root) {
            uint256 i = mapLevelType[_upperLevel];
            mapLevelType[_myaddr] = i+1;
            mapUpperLevel[_myaddr] = _upperLevel;
            mapLowerLevel[_upperLevel].push(_myaddr);
        }    
        addRelation(_myaddr);
    }

    function addRelation(address _addr) internal {
        if(mapUser[_addr] == 0) {
            users.push(_addr);
            mapUser[_addr] = users.length;
        }
    }

    function GetUpperRelation(address _addr) public view returns (address) {
        return mapUpperLevel[_addr];
    }

    function GetLowerRelation(address _addr) external view returns (address[] memory) {
        return mapLowerLevel[_addr];
    }

    function GetmapLowerLevelleamount(address _addr) public view returns (uint256){
        return mapLowerLevel[_addr].length;
    }

    function GetmapLevelType(address _addr) public view returns (uint256){
        return mapLevelType[_addr];
    }
    
    function SetRoot(address _root) public onlyOwner{
        require(_root != address(0), "root is zero address");
        root = _root;
        addRelation(_root);
    }
}