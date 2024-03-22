import "forge-std/Script.sol";
import "../src/KYCToken.sol";

contract DeployScript is Script {
    uint256 private deployerPrivateKey;
    address private ownerAddress;
    address private registryAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        ownerAddress = vm.envAddress("OWNER_ADDRESS");
        registryAddress = vm.envAddress("REGISTRY_ADDRESS");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        new KYCToken(ownerAddress, VerificationRegistry(registryAddress));
        vm.stopBroadcast();
    }
}