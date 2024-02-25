pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {VerificationRegistry, VerificationResult} from "../src/VerificationRegistry.sol";
import {VerifierInfo} from "../src/VerificationRegistry.sol";

contract VerificationRegistryTest is Test {
    VerificationRegistry public registry;
    address public owner;
    address public signer;
    address public subject;

    function setUp() public {
        owner = vm.addr(1);
        signer = vm.addr(2);
        subject = vm.addr(3);

        vm.prank(owner);
        registry = new VerificationRegistry(owner);
    }

    function testOwner() public {
        assertEq(registry.owner(), owner);
    }

    function testNoVerifierYet() public {
        assertEq(registry.getVerifierCount(), 0);

        assertFalse(registry.isVerifier(owner));

        vm.expectRevert("VerificationRegistry: Unknown Verifier Address");
        registry.getVerifier(owner);
    }

    function testAddVerifier() public {
        vm.prank(owner);
        registry.addVerifier(owner, VerifierInfo("ContactOwner", "did:example:owner", "https://example.com/owner", owner));

        assertEq(registry.getVerifierCount(), 1);
        assertTrue(registry.isVerifier(owner));
        assertFalse(registry.isVerified(owner));

        VerifierInfo memory info = registry.getVerifier(owner);
        assertEq(info.name, "ContactOwner");
        assertEq(info.did, "did:example:owner");
        assertEq(info.url, "https://example.com/owner");
        assertEq(info.signer, owner);
    }

    function testVerify() public {
        bytes memory signature;

        vm.expectRevert();
        registry.registerVerification(VerificationResult(
            "circle.com/credentials/kyc", subject, vm.getBlockTimestamp() + 300
        ), signature);
    }

}