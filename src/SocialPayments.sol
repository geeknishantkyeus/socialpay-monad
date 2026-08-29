// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SocialPayments {
    // --- Storage ---
    mapping(address => string) public usernames;
    mapping(address => uint256) public reputation;
    mapping(address => bool) public registered;
    mapping(address => mapping(address => bool)) public hasInteracted;

    struct Payment {
        address from;
        address to;
        uint256 amount;
        string note;
        uint256 timestamp;
    }

    mapping(address => Payment[]) public paymentHistory;

    // --- Events ---
    event UserRegistered(address indexed user, string username);
    event PaymentSent(address indexed from, address indexed to, uint256 amount, string note);
    event ReputationUpdated(address indexed user, uint256 newScore);

    // --- Modifiers ---
    modifier onlyRegistered() {
        require(registered[msg.sender], "User not registered");
        _;
    }

    // --- Functions ---
    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(!registered[msg.sender], "Already registered");
        require(bytes(usernames[msg.sender]).length == 0, "Username taken");

        usernames[msg.sender] = _username;
        registered[msg.sender] = true;
        reputation[msg.sender] = 10; // Starting reputation

        emit UserRegistered(msg.sender, _username);
    }

    function sendPayment(address _to, string memory _note) public payable onlyRegistered {
        require(_to != address(0), "Invalid address");
        require(msg.value > 0, "Amount must be > 0");
        require(bytes(_note).length <= 200, "Note too long");
        require(registered[_to], "Recipient not registered");

        // Update interaction
        hasInteracted[msg.sender][_to] = true;
        hasInteracted[_to][msg.sender] = true;

        // Send payment
        (bool success, ) = _to.call{value: msg.value}("");
        require(success, "Transfer failed");

        // Store payment
        paymentHistory[msg.sender].push(Payment({
            from: msg.sender,
            to: _to,
            amount: msg.value,
            note: _note,
            timestamp: block.timestamp
        }));

        paymentHistory[_to].push(Payment({
            from: msg.sender,
            to: _to,
            amount: msg.value,
            note: _note,
            timestamp: block.timestamp
        }));

        // Update reputation
        reputation[msg.sender] += 1;
        reputation[_to] += 1;

        emit PaymentSent(msg.sender, _to, msg.value, _note);
        emit ReputationUpdated(msg.sender, reputation[msg.sender]);
        emit ReputationUpdated(_to, reputation[_to]);
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }

    function getPaymentHistory(address _user) public view returns (Payment[] memory) {
        return paymentHistory[_user];
    }

    function getUserUsername(address _user) public view returns (string memory) {
        return usernames[_user];
    }

    function getPaymentCount(address _user) public view returns (uint256) {
        return paymentHistory[_user].length;
    }
}
