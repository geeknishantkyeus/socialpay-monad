// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SocialPayments} from "../src/SocialPayments.sol";

contract DeploySocialPayments is Script {
    function run() external {
        uint256 deployerPrivateKey = parsePrivateKey(vm.envString("PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        SocialPayments socialPayments = new SocialPayments();

        vm.stopBroadcast();

        console.log("SocialPayments deployed to:", address(socialPayments));
    }

    function parsePrivateKey(string memory value) internal pure returns (uint256) {
        bytes memory data = bytes(value);

        if (data.length >= 2 && data[0] == 0x22 && data[data.length - 1] == 0x22) {
            bytes memory unquoted = new bytes(data.length - 2);
            for (uint256 i = 1; i < data.length - 1; i++) {
                unquoted[i - 1] = data[i];
            }
            data = unquoted;
        }

        uint256 offset = 0;
        if (data.length >= 2 && data[0] == 0x30 && (data[1] == 0x78 || data[1] == 0x58)) {
            offset = 2;
        }

        require(data.length - offset == 64, "PRIVATE_KEY must be 64 hex chars");

        uint256 result;
        for (uint256 i = offset; i < data.length; i++) {
            uint8 c = uint8(data[i]);
            if (c >= 0x30 && c <= 0x39) {
                result = result * 16 + (c - 0x30);
            } else if (c >= 0x41 && c <= 0x46) {
                result = result * 16 + (c - 0x37);
            } else if (c >= 0x61 && c <= 0x66) {
                result = result * 16 + (c - 0x57);
            } else {
                revert("Invalid PRIVATE_KEY");
            }
        }

        return result;
    }
}
