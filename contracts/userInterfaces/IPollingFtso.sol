// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;
pragma abicoder v2;


interface IPollingFtso {

    /**
     * Struct holding the information about proposal properties
     */
    struct Proposal {
        string description;                // description of the proposal
        address proposer;                  // address of the proposer
        bool canceled;                     // flag indicating if proposal has been canceled
        uint256 voteStartTime;             // start time of voting window (in seconds from epoch)
        uint256 voteEndTime;               // end time of voting window (in seconds from epoch)
        uint256 threshold;                 //  number of votes (voter power) cast required for the proposal to pass
        uint256 majorityConditionBIPS;     // percentage in BIPS of the proper relation between FOR and AGAINST votes
        uint256 rewardEpochId;
    }

    /**
     * Struct holding the information about proposal voting
     */
    struct ProposalVoting {
        uint256 againstVotePower;           // accumulated vote power against the proposal
        uint256 forVotePower;               // accumulated vote power for the proposal
        mapping(address => bool) hasVoted;  // flag if a voter has cast a vote
    }

    /**
     * Enum describing a proposal state
     */
    enum ProposalState {
        Canceled,
        Pending,
        Active,
        Defeated,
        Succeeded
    }

    /**
     * Enum that determines vote (support) type
     * @dev 0 = Against, 1 = For
     */
    enum VoteType {
        Against,
        For
    }

    /**
     * Event emitted when a proposal is created
     */
    event FtsoProposalCreated(
        uint256 indexed proposalId,
        uint256 indexed rewardEpochId,
        address proposer,
        string description,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 threshold,
        uint256 majorityConditionBIPS
    );

    /**
     * Event emitted when a vote is cast
     */
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 forVotePower,
        uint256 againstVotePower
    );

    /**
     * Event emitted when a proposal is canceled
     */
    event ProposalCanceled(uint256 indexed proposalId);

    /**
     * Event emitted when parameters are set
     */
    event ParametersSet(
        uint256 votingDelaySeconds,
        uint256 votingPeriodSeconds,
        uint256 thresholdConditionBIPS,
        uint256 majorityConditionBIPS,
        uint256 proposalFeeValueWei
    );

    /**
     * Event emitted when maintainer is set
     */
    event MaintainerSet(address newMaintainer);

    /**
     * Event emitted when proxy voter is set
     */
    event ProxyVoterSet(address account, address proxyVoter);

    /**
     * Sets (or changes) contract's parameters. It is called after deployment of the contract
     * and every time one of the parameters changes.
     */
    function setParameters(
        uint256 _votingDelaySeconds,
        uint256 _votingPeriodSeconds,
        uint256 _thresholdConditionBIPS,
        uint256 _majorityConditionBIPS,
        uint256 _proposalFeeValueWei
    )
    external;

    /**
     * Cancels an existing proposal
     * @param _proposalId           Unique identifier of a proposal
     * Emits a ProposalCanceled event
     */
    function cancel(uint256 _proposalId) external;

    /**
     * Creates a new proposal
     * @param _description          String description of the proposal
     * @return _proposalId          Unique identifier of the proposal
     * Emits a FtsoProposalCreated event
     */
    function propose(
        string memory _description
    ) external payable returns (uint256);

    /**
     * @notice Casts a vote on a proposal
     * @param _proposalId           Id of the proposal
     * @param _support              A value indicating vote type (against, for)
     * @notice Emits a VoteCast event
     */
    function castVote(uint256 _proposalId, uint8 _support) external;

    /**
     * Sets a proxy voter for a voter (i.e. address that can vote in its name)
     * @param _proxyVoter           Address to register as a proxy (use address(0) to remove proxy)
     * Emits a ProxyVoterSet event
     */
    function setProxyVoter(address _proxyVoter) external;

    /**
     * @notice Returns the current state of a proposal
     * @param _proposalId           Id of the proposal
     * @return ProposalState enum
     */
    function state(uint256 _proposalId) external view returns (ProposalState);

    /**
     * @notice Returns whether a voter has cast a vote on a specific proposal
     * @param _proposalId           Id of the proposal
     * @param _voter                Address of the voter
     * @return True if the voter has cast a vote on the proposal, and false otherwise
     */
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool);

    /**
     * Returns information about the specified proposal
     * @param _proposalId               Id of the proposal
     * @return _description             Description of the proposal
     * @return _proposer                Address of the proposal submitter
     * @return _voteStartTime           Start time (in seconds from epoch) of the proposal voting
     * @return _voteEndTime             End time (in seconds from epoch) of the proposal voting
     * @return _threshold               Number of votes (voter power) cast required for the proposal to pass
     * @return _majorityConditionBIPS   Number of FOR votes, as a percentage in BIPS of the
     total cast votes, required for the proposal to pass
     */
    function getProposalInfo(
        uint256 _proposalId
    )
        external view
        returns (
            string memory _description,
            address _proposer,
            uint256 _voteStartTime,
            uint256 _voteEndTime,
            uint256 _threshold,
            uint256 _majorityConditionBIPS,
            uint256 _rewardEpochId
        );

    /**
     * Returns the description string that was supplied when the specified proposal was created
     * @param _proposalId           Id of the proposal
     * @return _description         Description of the proposal
     */
    function getProposalDescription(uint256 _proposalId) external view
        returns (string memory _description);

    /**
     * Returns id and description of the last created proposal
     * @return _proposalId          Id of the last proposal
     * @return _description         Description of the last proposal
     */
    function getLastProposal() external view
        returns ( uint256 _proposalId, string memory _description);

    /**
     * Returns number of votes for and against the specified proposal
     * @param _proposalId           Id of the proposal
     * @return _for                 Accumulated vote power for the proposal
     * @return _against             Accumulated vote power against the proposal
     */
    function getProposalVotes(
        uint256 _proposalId
    )
        external view
        returns (
            uint256 _for,
            uint256 _against
        );

    /**
     * Returns whether an account can create proposals
     * An address can make proposals if it is registered voter,
     * its proxy or the maintainer of the contract
     * @param _account              Address of the queried account
     * @return True if the queried account can create a proposal, false otherwise
     */
    function canPropose(address _account) external view returns (bool);

    /**
     * Returns whether an account can vote for a given proposal
     * @param _account              Address of the queried account
     * @param _proposalId           Id of the queried proposal
     * @return True if account is eligible to vote, false otherwise
     */
    function canVote(address _account, uint256 _proposalId) external view returns (bool);

}
