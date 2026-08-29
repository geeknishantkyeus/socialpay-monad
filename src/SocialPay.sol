// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SocialPay is ReentrancyGuard {
    error ProfileAlreadyExists();
    error ProfileNotFound();
    error InvalidHandle();
    error ZeroAmount();
    error NotProfileOwner();

    struct Profile {
        uint256 id;
        address owner;
        string handle;
        string displayName;
        string bio;
        uint256 totalTips;
        bool exists;
    }

    uint256 public profileCount;

    mapping(address => uint256) public profileIdByAddress;
    mapping(string => uint256) public profileIdByHandle;
    mapping(uint256 => Profile) public profiles;
    mapping(address => uint256) public totalTipsByAddress;

    event ProfileCreated(
        uint256 indexed id,
        address indexed owner,
        string handle,
        string displayName,
        string bio
    );

    event Tipped(
        uint256 indexed profileId,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event Withdrawn(address indexed recipient, uint256 amount);

    function createProfile(
        string calldata handle,
        string calldata displayName,
        string calldata bio
    ) external {
        if (bytes(handle).length == 0) revert InvalidHandle();
        if (profileIdByAddress[msg.sender] != 0) revert ProfileAlreadyExists();
        if (profileIdByHandle[handle] != 0) revert ProfileAlreadyExists();

        profileCount++;
        uint256 newId = profileCount;

        profiles[newId] = Profile({
            id: newId,
            owner: msg.sender,
            handle: handle,
            displayName: displayName,
            bio: bio,
            totalTips: 0,
            exists: true
        });

        profileIdByAddress[msg.sender] = newId;
        profileIdByHandle[handle] = newId;

        emit ProfileCreated(newId, msg.sender, handle, displayName, bio);
    }

    function tipByHandle(string calldata handle) external payable {
        uint256 amount = msg.value;
        if (amount == 0) revert ZeroAmount();

        uint256 profileId = profileIdByHandle[handle];
        if (profileId == 0) revert ProfileNotFound();

        Profile storage profile = profiles[profileId];
        profile.totalTips += amount;
        totalTipsByAddress[profile.owner] += amount;

        emit Tipped(profileId, msg.sender, profile.owner, amount);
    }

    function tipByAddress(address recipient) external payable {
        uint256 amount = msg.value;
        if (amount == 0) revert ZeroAmount();

        uint256 profileId = profileIdByAddress[recipient];
        if (profileId == 0) revert ProfileNotFound();

        Profile storage profile = profiles[profileId];
        profile.totalTips += amount;
        totalTipsByAddress[recipient] += amount;

        emit Tipped(profileId, msg.sender, recipient, amount);
    }

    function withdrawTips() external nonReentrant {
        uint256 amount = totalTipsByAddress[msg.sender];
        if (amount == 0) revert ZeroAmount();

        totalTipsByAddress[msg.sender] = 0;

        uint256 profileId = profileIdByAddress[msg.sender];
        if (profileId == 0) revert ProfileNotFound();

        Profile storage profile = profiles[profileId];
        profile.totalTips = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function getProfileByOwner(address owner) external view returns (Profile memory) {
        uint256 profileId = profileIdByAddress[owner];
        if (profileId == 0) revert ProfileNotFound();
        return profiles[profileId];
    }

    function getProfileByHandle(string calldata handle) external view returns (Profile memory) {
        uint256 profileId = profileIdByHandle[handle];
        if (profileId == 0) revert ProfileNotFound();
        return profiles[profileId];
    }

    function totalTipsForAddress(address owner) external view returns (uint256) {
        return totalTipsByAddress[owner];
    }

    function isHandleTaken(string calldata handle) external view returns (bool) {
        return profileIdByHandle[handle] != 0;
    }
}
