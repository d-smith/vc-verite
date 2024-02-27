
pragma solidity ^0.8.20;


import {Test, console2} from "forge-std/Test.sol";
import {KYCToken} from "../src/KYCToken.sol";
import {VerificationRegistry,VerifierInfo,VerificationResult,VerificationRecord} from "../src/VerificationRegistry.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract KYCTokenTest is Test {
    KYCToken public token;
    address public owner;
    address known;
    address unknown;
    address signer;
    uint256 signerKey = 100;
    VerificationRegistry public registry;

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function setUp() public {
        owner = vm.addr(1);
        known = vm.addr(2);
        unknown = vm.addr(3);
        signer = vm.addr(signerKey);

        vm.startPrank(owner);

        registry = new VerificationRegistry(owner);
        token = new KYCToken(owner,registry);

        vm.stopPrank();

    }

    function testOwner() public {
        assertEq(token.owner(), owner);
        assertEq(registry.owner(), owner);
    }

    function testInitialSupply() public {
        assertEq(token.balanceOf(owner), 100000000 * 10 ** token.decimals());
    }

    function testCannotSendToUnknown() public {
        vm.expectRevert("Destination account is not KYC'd");
        vm.prank(owner);
        token.transfer(unknown, 100);
    }

    function testCanSendToKYC() public {
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
            known, 
            expiration));

        // Build the digest
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            verificationResultHash
        ));
 
        // Sign the digest
        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        vm.stopPrank();

        signature = abi.encodePacked(r, s, v);

        vm.startPrank(owner);
        address recovered = ECDSA.recover(digest, signature);
        assertEq(recovered, signer);

        registry.registerVerification(VerificationResult(
            "circle.com/credentials/kyc", known, expiration),
        signature);

        assertEq(registry.getVerificationCount(), 1);

        VerificationRecord[] memory verrifications = registry.getVerificationsForSubject(known);
        assertEq(verrifications.length, 1);

        bytes32 uuid = verrifications[0].uuid;
        VerificationRecord memory record = registry.getVerification(uuid);
        assertEq(record.uuid, uuid);

        assertTrue(registry.isVerified(known));

       
        token.transfer(known, 100);
        assertEq(token.balanceOf(known), 100);

         vm.stopPrank();
    }


}