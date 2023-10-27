// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinDCXDao is Ownable{

constructor(address initialOwner) Ownable(initialOwner) {
    members[msg.sender] = Member(msg.sender, "chairman","");
    numOfMembers++; 
}

mapping(address => Member) public members;
uint256 public numOfMembers;

struct Member {
        address wallet;
        string name;
        string profilePictureUrl;
}

event MemberAdded(string message ,string name);

function addMember(address newMemberAddress ,string memory _name, string memory _profilePictureUrl) external membersOnly{
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(members[newMemberAddress].wallet == address(0), "Already a member");
        members[newMemberAddress] = Member(newMemberAddress, _name, _profilePictureUrl);
        numOfMembers++; 
        emit MemberAdded("welcome our newest memeber", _name);
}

modifier membersOnly() {
    require(members[msg.sender].wallet != address(0), "Only members can perform this action");
     _;
}

mapping(uint256 => Proposal) public proposals;
uint256 public numProposals;

struct Proposal {
    uint256 proposalId;
    address proposer;
    string title;
    string description;
    string attachmentIpfsHash;
    uint256 yesVotes;
    uint256 noVotes;
    bool votingClosed;
    mapping(address => bool) membersVoted;
    uint256 deadline;
    bool isapproved;
}

event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, string description, string attachmentIpfsHash, uint256 deadline );

//returns the proposal index
function createProposal(string memory _title, string memory _description ,string memory _attachmentIpfsHash,uint256 _deadlineInEpochSeconds )
    external
    membersOnly()
    returns (uint256)
{
    Proposal storage proposal = proposals[numProposals];
    proposal.proposalId = numProposals;
    proposal.title = _title;
    proposal.description = _description;
    proposal.attachmentIpfsHash = _attachmentIpfsHash;
    proposal.proposer = msg.sender;
    proposal.deadline = block.timestamp + _deadlineInEpochSeconds;
    numProposals++;
    emit ProposalCreated(proposal.proposalId, msg.sender, _title, _description, _attachmentIpfsHash, proposal.deadline);
    return numProposals - 1;
}


modifier activeProposalOnly(uint256 proposalIndex) {
    require(
        proposals[proposalIndex].deadline > block.timestamp,
        "DEADLINE_EXCEEDED"
    );
    _;
}

enum Vote {
    YES, 
    NO 
}

event NewVoteCasted(string message);

function voteOnProposal(uint256 _proposalId, Vote vote)
    external
    membersOnly
    activeProposalOnly(_proposalId)
{
    Proposal storage proposal = proposals[_proposalId];

    require(block.timestamp <= proposal.deadline, "Voting has ended");
    require(proposal.membersVoted[msg.sender] == false, "you have already voted");

    proposal.membersVoted[msg.sender] = true;
    if (vote == Vote.YES) {
        proposal.yesVotes += 1;
    } else {
        proposal.noVotes += 1;
    }
    
    emit NewVoteCasted("A new vote has been casted.");
}


event VotingResult(string message, uint256 votesInFavor, uint256 votesAgainst);
event VotingDeadlineExtended(string message, uint256 proposalId, uint256 deadline);

function tallyVotes(uint256 _proposalId) external membersOnly{
    Proposal storage proposal = proposals[_proposalId];
    require(block.timestamp > proposal.deadline, "Voting is still ongoing");
    require(!proposal.votingClosed, "Votes are already tallied");

    uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
    uint256 requiredVotes = (numOfMembers * 80) / 100;

    if (totalVotes >= requiredVotes) {
        proposal.votingClosed = true;
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.isapproved = true;
            emit VotingResult("The proposal is approved with ",proposal.yesVotes , proposal.noVotes);
        }
        else {emit VotingResult("The proposal is rejected with ",proposal.yesVotes , proposal.noVotes);}
    } else {
        proposal.deadline = proposal.deadline + 5 minutes;
        emit VotingDeadlineExtended("THE VOTING DEADLINE IS EXTENDED FOR PROPOSAL", proposal.proposalId, proposal.deadline);
    }
}
}
