// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}

contract NftStake {
    IERC20 token;
    IERC721 nftToken;


    struct User{
        uint256[] tokens;
        uint256[] amount;
        uint256[] updateTime;
        bool[] first;
        bool[] miner;
    }

    mapping (address=>User) internal strUser;

    constructor(IERC721 _nftToken,IERC20 _token){
        token = _token;
        nftToken = _nftToken;
    }

    receive() external payable {}

    function stake(uint256 tokenId) external{
        nftToken.transferFrom(msg.sender,address(this),tokenId);
        User storage user = strUser[msg.sender];
        if (user.tokens.length==0){
            user.tokens.push(tokenId);
            user.amount.push(225*10**18);
            user.first.push(true);
            user.updateTime.push(block.timestamp);
            user.miner.push(true);
            //
        }else{
            bool have = false;
            for (uint256 i;i<user.tokens.length;i++){
                if (tokenId==user.tokens[i]){
                    user.first[i] = false;
                    user.updateTime[i] = block.timestamp;
                    user.miner[i]=true;
                    have = true;
                }
            }
            if (have==false){
                user.tokens.push(tokenId);
                user.amount.push(225*10**18);
                user.first.push(true);
                user.updateTime.push(block.timestamp);
                user.miner.push(true);
                //
            }
        }
    }

    function select() public view returns(uint256) {
        uint256 rewardPerSec = 5*10**18 / uint256(86400);
        User storage _userInfo = strUser[msg.sender];
        uint256 reward = 0;
        for (uint256 i=0;i<_userInfo.tokens.length;i++){
            if (_userInfo.miner[i]==true && _userInfo.amount[i]>0){
                uint256 rewardTmp = (block.timestamp - _userInfo.updateTime[i]) * rewardPerSec;
                if (rewardTmp>_userInfo.amount[i]){
                    reward = reward+_userInfo.amount[i];
                }else {
                    reward = reward+rewardTmp;
                }
            }
        }
        return reward;
    }
    function earn(address user) external{
        uint256 rewardPerSec = 5*10**18 / uint256(86400);
        User storage _userInfo = strUser[user];
        uint256 reward = 0;
        for (uint256 i=0;i<_userInfo.tokens.length;i++){
            if (_userInfo.miner[i]==true && _userInfo.amount[i]>0){
                uint256 rewardTmp = (block.timestamp - _userInfo.updateTime[i]) * rewardPerSec;
               
                if (rewardTmp>_userInfo.amount[i]){
                    reward = reward+_userInfo.amount[i];
                    _userInfo.amount[i] = 0;
                }else {
                    reward = reward+rewardTmp;
                    _userInfo.amount[i] = _userInfo.amount[i]-rewardTmp;
                }
                _userInfo.updateTime[i] = block.timestamp;
            }
        }
        payable(user).transfer(reward);
        token.transfer(user, reward);
    }

    function withdraw(uint256 tokenId) external{
        User storage _userInfo = strUser[msg.sender];
        uint256 rewardPerSec = 5*10**18 / uint256(86400);
        for (uint256 i=0;i<_userInfo.tokens.length;i++){
            if (_userInfo.tokens[i]==tokenId){
                uint256 rewardTmp = (block.timestamp - _userInfo.updateTime[i]) * rewardPerSec;
                uint256 reward = 0;
                if (rewardTmp > _userInfo.amount[i]){
                    reward = reward+_userInfo.amount[i];
                    _userInfo.amount[i] = 0;
                }else {
                    reward = reward+rewardTmp;
                    _userInfo.amount[i] = _userInfo.amount[i]-rewardTmp;
                }
                _userInfo.updateTime[i] = block.timestamp;
                token.transfer(msg.sender, reward);
                payable(msg.sender).transfer(reward);
                nftToken.transferFrom(address(this),msg.sender,tokenId);
                _userInfo.miner[i] = false;
                _userInfo.first[i] = false;
                _userInfo.updateTime[i] = block.timestamp;
            }
        }
    }

    function getTokens() public view returns(uint256[] memory){
        User storage _userInfo = strUser[msg.sender];
        uint256 big=0;
        for (uint256 i = 0;i<_userInfo.tokens.length;i++){
            if (_userInfo.miner[i]==true){
                big++;
            }
        }
        uint256[] memory haves = new uint256[](big);
        for (uint256 i = 0;i<_userInfo.tokens.length;i++){
            if (_userInfo.miner[i]==true){
                for (uint256 j=0;j<big;j++){
                    if (haves[j]==0){
                        haves[j]=_userInfo.tokens[i];
                        break;
                    }
                }
            }
        }
        return haves;
    }

    function getUser() public view returns(User memory){
        User storage _userInfo = strUser[msg.sender];
        return _userInfo;
    }

    function getOwner(address _add) public view returns(User memory){
        User storage _userInfo = strUser[_add];
        return _userInfo;
    }
}