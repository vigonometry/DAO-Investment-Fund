pragma solidity ^0.8.7;

import "
import "./TokenCreation.sol";

contract Loan {
    LumiDAOToken private lumidao

    enum LoanStatus {Pending, Approved};
    uint8 public constant FEE_PERCENTAGE = 0.20; //10% Fee

    struct loanTerms {
        address borrower;
        uint256 loanLumiAmount;
        uint256 loanFee;
        uint256 ethCollateralAmount;
        uint32 repayByTimestamp;
        LoanStatus status;
    };

    mapping(address => loanTerms) public loans;

    modifier onlyStakeHolders() {
        require(lumidao.stakeholders[msg.sender] == true);
        _;
    }

    constructor (address[] memory _stakeholders){
        for (uint i = 0; i < _stakeholders.length; i += 1){
            lumidao.addStakeholder(_stakholders[i]);
        }
    }

    function getLoanData(address _stakeholder) 
    external 
    view 
    returns(loanTerms){
        return loans[_stakeholder];
    }

    function applyForLoan( 
        uint32 _duration,
        uint256 _ethCollateralAmount
    )
    external
    onlyStakeHolders{
        loanTerms newLoan = loanTerms(
            msg.sender,
            numTokens(_ethCollateralAmount), //function numTokens to be created
            numTokens(_ethCollateralAmount) * FEE_PERCENTAGE; //function numTokens to be created
            _ethCollateralAmount;
            now + _duration;
            Pending;
        );
        loans[msg.sender] = newLoan;
    }

    function approveLoan(address _stakeholder) external onlyAdmins{
        loans[_stakeholder].status = Approved;
        lumidao._transferToken(msg.sender, _stakeholder, loans[_stakeholder];
    }

    function rejectLoan(address _stakeholder) external onlyAdmins{
        loans[_stakeholder] = loanTerms();
    }

    function repayLoan(address payable _recipient, uint256 _amount) 
    external 
    onlyStakeHolders{
        require(now < loans[_stakeholder].repayByTimestamp, "The due date of your loan has passed!");
        lumidao._transferToken(msg.sender, _recipient, _amount);
        loans[_stakeholder].loanLumiAmount -= _amount;
    }

    function liquidateAccount(address _stakeholder) external onlyAdmins{
        send(_stakeholder, msg.sender, loans[_stakeholder].ethCollateralAmount);
        loans[_stakeholder] = loanTerms();
    }
}