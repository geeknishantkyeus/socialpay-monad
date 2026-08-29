// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/SocialPay.sol";

contract SocialPayTest is Test {
    SocialPay public socialPay;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        socialPay = new SocialPay();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_createProfile() public {
        vm.prank(alice);
        socialPay.createProfile("alice", "Alice", "Builder");

        SocialPay.Profile memory profile = socialPay.getProfileByOwner(alice);
        assertEq(profile.owner, alice);
        assertEq(profile.handle, "alice");
        assertEq(profile.displayName, "Alice");
        assertEq(profile.bio, "Builder");
        assertEq(profile.totalTips, 0);
        assertEq(socialPay.profileIdByAddress(alice), 1);
    }

    function test_tipProfileByHandle() public {
        vm.prank(alice);
        socialPay.createProfile("alice", "Alice", "Builder");

        vm.prank(bob);
        socialPay.tipByHandle{value: 1 ether}("alice");

        assertEq(address(socialPay).balance, 1 ether);
        assertEq(socialPay.totalTipsForAddress(alice), 1 ether);
    }

    function test_withdrawTips() public {
        vm.prank(alice);
        socialPay.createProfile("alice", "Alice", "Builder");

        vm.prank(bob);
        socialPay.tipByHandle{value: 1.5 ether}("alice");

        uint256 aliceBefore = alice.balance;
        vm.prank(alice);
        socialPay.withdrawTips();

        assertEq(alice.balance, aliceBefore + 1.5 ether);
        assertEq(socialPay.totalTipsForAddress(alice), 0);
    }

    function test_rejectDuplicateHandle() public {
        vm.prank(alice);
        socialPay.createProfile("alice", "Alice", "Builder");

        vm.expectRevert(SocialPay.ProfileAlreadyExists.selector);
        vm.prank(bob);
        socialPay.createProfile("alice", "Bob", "Another");
    }
}
