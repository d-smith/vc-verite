pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {VerificationRegistry, VerificationResult, VerificationRecord} from "../src/VerificationRegistry.sol";
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

        function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function testVerify() public {
        bytes memory signature;
        uint256 expiration = block.timestamp + 300;

        // Register a verifier
        vm.startPrank(owner);

        registry.addVerifier(owner, VerifierInfo(
            stringToBytes32("VerificationRegistry"), "did:verificationregistry:contract", "https://example.com/owner", signer));

        assertEq(registry.getVerifierCount(), 1);
        vm.stopPrank();

        // Create the domain separator
        bytes32 TYPE_HASH =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        bytes32 domainSeparator = keccak256(abi.encode(TYPE_HASH, 
                        keccak256(bytes("VerificationRegistry")), 
                        keccak256(bytes("1.0")), 
                        block.chainid, address(registry)));

        // Build the structure hash
        bytes32 VERIFICATION_RESULT_TYPE_HASH = keccak256("VerificationResult(string schema,address subject,uint256 expiration)");
        bytes32 verificationResultHash = keccak256(abi.encode(VERIFICATION_RESULT_TYPE_HASH, 
            keccak256(bytes("circle.com/credentials/kyc")), 
            subject, 
            expiration));

        // Build the digest
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            verificationResultHash
        ));
 
        // Sign the digest
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, digest);
        vm.stopPrank();

        signature = abi.encodePacked(r, s, v);

        vm.startPrank(owner);
        address recovered = ECDSA.recover(digest, signature);
        assertEq(recovered, signer);

        registry.registerVerification(VerificationResult(
            "circle.com/credentials/kyc", subject, expiration),
        signature);

        assertEq(registry.getVerificationCount(), 1);

        VerificationRecord[] memory verrifications = registry.getVerificationsForSubject(subject);
        assertEq(verrifications.length, 1);

        bytes32 uuid = verrifications[0].uuid;
        VerificationRecord memory record = registry.getVerification(uuid);
        assertEq(record.uuid, uuid);

        vm.stopPrank();
    }

}