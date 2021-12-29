pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LumiDAOToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using Math for uint256;
    mapping (address => uint) private balances;
    address[] internal stakeholders;

    constructor() ERC20("LumiDAO", "LDT") ERC20Permit("LumiDAO") {}

    function _afterTokenTransfer(address from, address to, uint256 amount)  
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    event deposit(uint256 value);
    event withdraw(uint256 value);

    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(address _stakeholder) public {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }
    
    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    function createStake(uint256 _stake) public {
       _burn(msg.sender, _stake);
       if(balances[msg.sender] == 0) addStakeholder(msg.sender);
       balances[msg.sender] = balances[msg.sender] + _stake;
    }

    function removeStake(uint256 _stake) public {
        balances[msg.sender] = balances[msg.sender] - _stake;
        if(balances[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, _stake);
    }

    function totalStakes() public view returns(uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes + balances[stakeholders[s]];
        }
        return _totalStakes;
    }

    modifier hasBalance(uint256 amount) {
        require(balances[msg.sender] >= amount);
        _;
    }

    function withdrawToken(uint withdrawAmount) public hasBalance(withdrawAmount) returns (uint){
        address sender = msg.sender;
        balances[sender] -= withdrawAmount;
        transfer(sender, withdrawAmount);
        // _mint(msg.sender, reward);
        emit withdraw(withdrawAmount);
        return balances[sender];
    }

    function depositToken(uint depositAmount) public returns (uint){
        address sender = msg.sender;
        balances[sender] += depositAmount;
        transferFrom(sender, address(this), depositAmount);
        emit withdraw(depositAmount);
        return balances[sender];
    }

    function balance() public view returns (uint) {
        return balances[msg.sender];
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