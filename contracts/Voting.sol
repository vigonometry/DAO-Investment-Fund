pragma solidity ^0.8.2;
import "./TokenPool.sol";
import "./LumiDAOToken.sol";
contract Voting is TokenPool, LumiDAOToken{
    LumiDAOToken private lumidao;
    uint256 public nextProposalId = 0;
    uint32 public constant ONE_HUNDRED_AND_EIGHTY_DAYS = 15552000; //180 days in epoch time

    enum Status {ongoing, approved, rejected}


    //Structs

    struct VoteInfo{
        bool hasVoted; //checks if the member has already voted
        address stakeholder;
        uint256 weight; //amount of tokens staked for Vote
        bool inFavor;
    }

    struct Proposal{
        bool exists;
        uint256 proposalId;
        bytes32 name;
        string proposalDetails;
        uint256 amount;
        address payable recipient;
        VoteInfo[] votesInFavor;
        VoteInfo[] votesAgainst;
        uint256 creationTime;
        uint256 endTime;
        Status status;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => VoteInfo) public votes;

    modifier onlyStakeholders(){
        (bool _isStakeholder, ) = tokenPool.isStakeholder(msg.sender);
        require(_isStakeholder,"Stakeholder does not exist.");
        _;
    }

    constructor (address[] memory _stakeholders){
        for (uint i = 0; i < _stakeholders.length; i += 1){
            tokenPool.addStakeholder(_stakeholders[i]);
        }
    }

    //Events
    event proposalCreation (
        Proposal _newProposal
    );

    event castVote (
        VoteInfo _voteData
    );

    //Getters

    function getProposal(uint256 _proposalId)
    external 
    view
    returns (Proposal memory){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        return proposals[_proposalId];
    }

    function getVotesInFavor(uint256 _proposalId)
    external
    view
    returns (VoteInfo[] memory){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        return proposals[_proposalId].votesInFavor;
    }


    function getVotesAgainst(uint256 _proposalId)
    external
    view
    returns (VoteInfo[] memory){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        return proposals[_proposalId].votesAgainst;
    }

    //Proposal related functions


    function createProposal(
        bytes32 _name,
        string memory _proposalDetails,
        uint256 _amount,
        address payable _recipient
    ) 
    public
    onlyStakeholders{
        require(lumidao.balance() > 0, "Funds unavailable");
        require(!proposals[nextProposalId].exists);
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.exists = true;
        newProposal.proposalId = nextProposalId;
        newProposal.name = _name;
        newProposal.proposalDetails = _proposalDetails;
        newProposal.amount = _amount;
        newProposal.recipient = _recipient;
        newProposal.creationTime = block.timestamp;
        newProposal.endTime = newProposal.creationTime + ONE_HUNDRED_AND_EIGHTY_DAYS;
        newProposal.status = Status.ongoing;
        nextProposalId += 1;

        emit proposalCreation (
            newProposal
        );
    }

    function setProposalStatus(uint256 _proposalId)
    external
    onlyAdmins(msg.sender){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        Proposal storage p = proposals[_proposalId];

        uint256 weightInFavor = 0;
        uint256 weightAgainst = 0;


        if ((block.timestamp >= p.endTime)){

            for (uint256 i = 0; i < p.votesInFavor.length; i += 1){
            weightInFavor += p.votesInFavor[i].weight;
            }

            for (uint256 j = 0; j < p.votesAgainst.length; j += 1){
            weightAgainst += p.votesAgainst[j].weight;
            }

            if (weightInFavor > weightAgainst){
                p.status = Status.approved;
                lumidao.rewardUser(p.recipient, 100);
            } else {
                p.status = Status.rejected;
                tokenPool.transferFrom(p.recipient, tx.origin, p.amount);
            }
        }
    }

    //Voting related functions



    function vote(
        uint256 _proposalId,
        uint256 _weight, 
        bool _inFavor
        ) 
        external 
        onlyStakeholders{
        require(proposals[_proposalId].exists, "This proposal does not exist");
        require(votes[msg.sender].hasVoted == false, "Investor can only vote once for a proposal");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting time has elapsed for this proposal");

        votes[msg.sender] = VoteInfo(
            true,
            msg.sender,
            _weight,
            _inFavor
        );

        Proposal storage p = proposals[_proposalId];
        VoteInfo storage voteData = votes[msg.sender];
        if (_inFavor){
            p.votesInFavor.push(voteData);
        } else {
            p.votesAgainst.push(voteData);
        }
        lumidao.transferFrom(msg.sender, tx.origin, _weight);
        emit castVote(
            voteData
        );      
    }
}
