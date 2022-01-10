pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenPool.sol";

contract LumiDAOToken is TokenPool{
    event deposit(uint256 value);
    event withdraw(uint256 value);
    TokenPool public tokenPool;

    modifier hasBalance(uint256 amount) {
        require(balances[msg.sender] >= amount);
        _;
    }

    function withdrawToken(uint withdrawAmount) public hasBalance(withdrawAmount) returns (uint) {
        address sender = msg.sender;
        balances[sender] -= withdrawAmount;
        transfer(sender, withdrawAmount);
        emit withdraw(withdrawAmount);
        return balances[sender];
    }

    function purchaseToken(uint depositAmount) public returns (uint){
        address sender = msg.sender;
        balances[sender] += depositAmount;
        transferFrom(sender, address(this), depositAmount);
        emit withdraw(depositAmount);
        return balances[sender];
    }

    function depositToken(address[] memory _admins, uint256 amount) public onlyAdmins(msg.sender) {
        for (uint i = 0; i < _admins.length; i++) {
            balances[_admins[i]] += amount;
        }
    }

    function rewardUser(address _stakeholder, uint256 rewardAmount) public onlyOwner returns (bool) {
        tokenPool.transferFrom(msg.sender, _stakeholder, rewardAmount);
    }
    

    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getBalance(address _stakeholder) public view returns (uint) {
        return balances[_stakeholder];
    }

    function calculateReward(address _stakeholder) public view returns(uint256) {
        return balances[_stakeholder] / 100;
    }

    function distributeRewards() public onlyOwner {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            balances[stakeholder] = balances[stakeholder] + reward;
        }
    }
}