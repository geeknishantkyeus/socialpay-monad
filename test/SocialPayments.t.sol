// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {SocialPayments} from "../src/SocialPayments.sol";

contract SocialPaymentsTest is Test {
    SocialPayments public socialPayments;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    event UserRegistered(address indexed user, string username);
    event PaymentSent(address indexed from, address indexed to, uint256 amount, string note);

    function setUp() public {
        socialPayments = new SocialPayments();
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
    }

    // ============ Registration Tests ============

    function test_RegisterUser_Success() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        assertEq(socialPayments.getUserUsername(alice), "alice");
        assertEq(socialPayments.getUserReputation(alice), 10);
        assertTrue(socialPayments.registered(alice));
        assertEq(socialPayments.usernameToAddress("alice"), alice);
    }

    function test_RegisterUser_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit UserRegistered(alice, "alice");

        vm.prank(alice);
        socialPayments.registerUser("alice");
    }

    function test_RegisterUser_RevertOnEmptyUsername() public {
        vm.prank(alice);
        vm.expectRevert("Username cannot be empty");
        socialPayments.registerUser("");
    }

    function test_RegisterUser_RevertOnDuplicateRegistration() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(alice);
        vm.expectRevert("Already registered");
        socialPayments.registerUser("alice2");
    }

    function test_RegisterUser_RevertOnTakenUsername() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        vm.expectRevert("Username taken");
        socialPayments.registerUser("alice");
    }

    function test_RegisterUser_MultipleUsers() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        vm.prank(charlie);
        socialPayments.registerUser("charlie");

        assertEq(socialPayments.getUserUsername(alice), "alice");
        assertEq(socialPayments.getUserUsername(bob), "bob");
        assertEq(socialPayments.getUserUsername(charlie), "charlie");
    }

    // ============ Username Resolution Tests ============

    function test_GetAddressByUsername_Success() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        assertEq(socialPayments.getAddressByUsername("alice"), alice);
    }

    function test_GetAddressByUsername_ReturnsZeroForUnknown() public {
        assertEq(socialPayments.getAddressByUsername("unknown"), address(0));
    }

    // ============ Payment Tests ============

    function test_SendPayment_Success() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;

        vm.prank(alice);
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");

        assertEq(alice.balance, aliceBalanceBefore - 1 ether);
        assertEq(bob.balance, bobBalanceBefore + 1 ether);
        assertEq(socialPayments.getUserReputation(alice), 11);
        assertEq(socialPayments.getUserReputation(bob), 11);
    }

    function test_SendPayment_EmitsEvent() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        vm.expectEmit(true, true, false, true);
        emit PaymentSent(alice, bob, 1 ether, "Coffee");

        vm.prank(alice);
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");
    }

    function test_SendPayment_UpdatesHistory() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        vm.prank(alice);
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");

        assertEq(socialPayments.getPaymentCount(alice), 1);
        assertEq(socialPayments.getPaymentCount(bob), 1);

        SocialPayments.Payment[] memory aliceHistory = socialPayments.getPaymentHistory(alice);
        assertEq(aliceHistory[0].from, alice);
        assertEq(aliceHistory[0].to, bob);
        assertEq(aliceHistory[0].amount, 1 ether);
        assertEq(aliceHistory[0].note, "Coffee");
    }

    function test_SendPayment_RevertOnUnregisteredSender() public {
        vm.prank(bob);
        socialPayments.registerUser("bob");

        vm.prank(alice);
        vm.expectRevert("User not registered");
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");
    }

    function test_SendPayment_RevertOnUnregisteredRecipient() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(alice);
        vm.expectRevert("Recipient not registered");
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");
    }

    function test_SendPayment_RevertOnZeroAmount() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        vm.prank(alice);
        vm.expectRevert("Amount must be > 0");
        socialPayments.sendPayment{value: 0}(bob, "Coffee");
    }

    function test_SendPayment_RevertOnInvalidRecipient() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(alice);
        vm.expectRevert("Invalid address");
        socialPayments.sendPayment{value: 1 ether}(address(0), "Coffee");
    }

    function test_SendPayment_RevertOnNoteTooLong() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        string memory longNote = new string(201);
        vm.prank(alice);
        vm.expectRevert("Note too long");
        socialPayments.sendPayment{value: 1 ether}(bob, longNote);
    }

    // ============ Reputation Tests ============

    function test_Reputation_IncreasesOnPayment() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        assertEq(socialPayments.getUserReputation(alice), 10);
        assertEq(socialPayments.getUserReputation(bob), 10);

        vm.prank(alice);
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");

        assertEq(socialPayments.getUserReputation(alice), 11);
        assertEq(socialPayments.getUserReputation(bob), 11);
    }

    function test_Reputation_MultiplePayments() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(alice);
            socialPayments.sendPayment{value: 0.1 ether}(bob, "Payment");
        }

        assertEq(socialPayments.getUserReputation(alice), 15);
        assertEq(socialPayments.getUserReputation(bob), 15);
    }

    // ============ View Function Tests ============

    function test_GetUserReputation() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        assertEq(socialPayments.getUserReputation(alice), 10);
    }

    function test_GetUserUsername() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        assertEq(socialPayments.getUserUsername(alice), "alice");
    }

    function test_GetPaymentCount_ZeroForNewUser() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        assertEq(socialPayments.getPaymentCount(alice), 0);
    }

    // ============ CEI Pattern Tests ============

    function test_SendPayment_CEI_Pattern() public {
        vm.prank(alice);
        socialPayments.registerUser("alice");

        vm.prank(bob);
        socialPayments.registerUser("bob");

        vm.prank(alice);
        socialPayments.sendPayment{value: 1 ether}(bob, "Coffee");

        assertEq(socialPayments.getUserReputation(alice), 11);
        assertEq(socialPayments.getUserReputation(bob), 11);
        assertEq(socialPayments.getPaymentCount(alice), 1);
        assertEq(socialPayments.getPaymentCount(bob), 1);
    }
}
