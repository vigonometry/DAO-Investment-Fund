pragma solidity ^0.8.7;

import "./TokenPool.sol";
import "./LumiDAOToken.sol";

contract Loan is TokenPool, LumiDAOToken{
    LumiDAOToken private lumidao;

    enum LoanStatus {Pending, Approved}
    uint8 public constant FEE_PERCENTAGE = 10;

    struct loanTerms {
        address borrower;
        uint256 loanLumiAmount;
        uint256 loanFee;
        uint256 ethCollateralAmount;
        uint256 repayByTimestamp;
        LoanStatus status;
    }

    mapping(address => loanTerms) public loans;

    modifier onlyStakeholders(){
        (bool _isStakeholder, ) = tokenPool.isStakeholder(msg.sender);
        require(_isStakeholder,"Stakeholder does not exist.");
        _;
    }

    constructor (address[] memory _stakeholders){
        for (uint i = 0; i < _stakeholders.length; i += 1){
            lumidao.addStakeholder(_stakeholders[i]);
        }
    }

    function getLoanData(address _stakeholder) 
    external 
    view 
    returns(loanTerms memory){
        return loans[_stakeholder];
    }

    function applyForLoan( 
        uint32 _duration,
        uint256 _numTokensRequested,
        uint256 _ethCollateralAmount
    )
    external
    onlyStakeholders{
        loanTerms memory newLoan = loanTerms(
            msg.sender,
            _numTokensRequested,
            _numTokensRequested * FEE_PERCENTAGE,
            _ethCollateralAmount,
            block.timestamp + _duration,
            LoanStatus.Pending
        );
        loans[msg.sender] = newLoan;
    }

    function approveLoan(address _stakeholder) external onlyAdmins(msg.sender){
        loans[_stakeholder].status = LoanStatus.Approved;
        lumidao.transferFrom(msg.sender, _stakeholder, loans[_stakeholder].loanLumiAmount);
    }

    // function rejectLoan(address _stakeholder) external onlyAdmins(msg.sender){
    //     loans[_stakeholder];
    // }

    function repayLoan(address payable _recipient, uint256 _amount) 
    external 
    onlyStakeholders{
        require(block.timestamp < loans[_recipient].repayByTimestamp, "The due date of your loan has passed!");
        lumidao.transferFrom(msg.sender, _recipient, _amount);
        loans[_recipient].loanLumiAmount -= _amount;
    }

    // function liquidateAccount(address _stakeholder) external onlyAdmins(msg.sender){
    //     transfer(_stakeholder, msg.sender, loans[_stakeholder].ethCollateralAmount);
    //     loans[_stakeholder] = loanTerms();
    // }
}