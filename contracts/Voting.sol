pragma solidity ^0.8.2;

import "../utils/AdminControls.sol";
import "./TokenCreation.sol";

/**
@title A voting system for investment proposals within a DAO
@author Vigneshwar Hariharan
@notice You can use this contract to implement a voting system within a DAO
@dev Some functions imported from TokenCreation.sol are still under development
@custom:testing This is a contract still under testing
 */
contract Voting{
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
    };

    struct Proposal{
        bool exists;
        uint256 proposalId;
        bytes32 name;
        string proposalDetails;
        uint256 amount;
        address payable recipient;
        VoteInfo[] votesInFavor;
        VoteInfo[] votesAgainst;
        uint32 creationTime;
        uint32 endTime;
        Status status;
    };

    mapping(uint256 => Proposal) public proposals;
    mapping(address => VoteInfo) public votes;

    modifier onlyStakeholders(){
        require(lumidao.stakeholders[msg.sender] == true);
        _;
    }

    constructor (address[] memory _stakeholders){
        for (uint i = 0; i < _stakeholders.length; i += 1){
            lumidao.addStakeholder(_stakholders[i]);
        }
    }

    //Events
    event proposalCreation (
        Proposal _newProposal;
    )

    event castVote (
        VoteInfo _voteData;
    )

    //Getters
    /**
    @notice This function retrieves proposal data given a proposalId
    @param[in] _proposalId, unique Id of a proposal stored within a mapping
    @return returns the proposal from the mapping if it exists, else throws an error
     */
    function getProposal(uint256 _proposalId)
    external 
    view
    returns (Proposal memory){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        return proposals[_proposalId];
    }

    /**
    @notice This function retrieves all proposal datas
    @return returns all existing proposals in the form of an array
     */

    function getAllProposals()
    external
    view
    returns (Proposal[] memory){
        Proposal[] memory allProposals;
        for (uint256 i = 0; i < nextProposalId; i += 1){
            allProposals.push(proposals[i]);
        }
        return allProposals;
    }

    /**
    @notice This function retrieves all votes in favor of a proposal
    @param[in] _proposalId, unique Id of a proposal stored within a mapping
    @return returns an array with votes in favor of the proposal if it exists, else throws an error
     */

    function getVotesInFavor(uint256 _proposalId)
    external
    view
    returns (VoteInfo[] memory){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        return proposals[_proposalId].votesInFavor;
    }

    /**
    @notice This function retrieves all votes against of a proposal
    @param[in] _proposalId, unique Id of a proposal stored within a mapping
    @return returns an array with votes against a proposal if it exists, else throws an error
     */

    function getVotesAgainst(uint256 _proposalId)
    external
    view
    returns (VoteInfo[] memory){
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        return proposals[_proposalId].votesAgainst;
    }

    //Proposal related functions

    /**
    @notice This function is used by members of the DAO to create a proposal
    @param[in] _name Short name of the proposal
    @param[in] _proposalDetails Short description of what the proposal entails
    @param[in] _amount Amount willing to be staked by member to create proposal
    @param[in] _recipient Address of the proposer
    @param[out] proposals The proposals mapping is initialised with the Proposal data
     */

    function createProposal(
        bytes32 memory _name,
        string memory _proposalDetails,
        uint256 _amount,
        address payable _recipient,
    ) 
    public
    onlyStakeholders{
        require(lumidao.balance() > 0, "Funds unavailable");
        proposals[nextProposalId] = Proposal(
            true,
            nextProposalId,
            _name,
            _proposalDetails,
            _amount,
            _recipient.
            {},
            {},
            now,
            now + ONE_HUNDRED_AND_EIGHTY_DAYS,
            ongoing
        );
        Proposal storage newProposal = proposal[nextProposalId]
        nextProposalId += 1;

        emit proposalCreation (
            newProposal
        );
    }

    /**
    @notice This function is used by admins of the DAO to set the status of a proposal
    @param[in] _proposalId unique Id of a proposal stored within a mapping
    @param[out] proposals The status of the proposal within the mapping is updated
     */

    function setProposalStatus(uint256 _proposalId)
    external
    onlyAdmins{
        require(proposals[_proposalId].exists, "This proposal does not exist!");
        Proposal storage p = proposals[proposalId];

        uint256 weightInFavor = 0;
        uint256 weightAgainst = 0;


        if ((now >= p.endTime)){

            for (uint256 i = 0; i < p.votesInFavor; i += 1){
            weightInFavor += p.votesInFavor[i].weight;
            }

            for (uint256 j = 0; j < p.votesAgainst; j += 1){
            weightAgainst += p.votesAgainst[i].weight;
            }

            if (weightInFavor > weightAgainst){
                p.status = approved;
                lumidao.rewardUser(p.recipient);
            } else {
                p.status = rejected;
                lumidao._burn(p.recipient, _amount);
            }
        }
    }

    //Voting related functions

    /**
    @notice This function is used by members of the DAO to cast a vote on a proposal
    @param[in] _proposalId unique Id of a proposal stored within a mapping
    @param[in] _weight Amount of token staked by member in casting a vote
    @param[in] _inFavor Boolean value for voter to indicate if they are
    in favor or against a proposal
    @param[out] proposals The VoteInfo arrays within the relevant proposal in the proposals mapping
    is updated with the vote data.
     */

    function vote(
        uint256 _proposalId,
        uint256 _weight, 
        bool _inFavor,
        ) 
        external 
        onlyStakeholders{
        require(proposals[_proposalId].exists, "This proposal does not exist")
        require(votes[msg.sender].hasVoted == false, "Investor can only vote once for a proposal");
        require(now < p.endTime, "Voting time has elapsed for this proposal");

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
        lumidao._transfer(msg.sender, tx.origin, _weight);
        emit castVote(
            voteData
        );      
    }
}