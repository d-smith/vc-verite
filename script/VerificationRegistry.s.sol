import "forge-std/Script.sol";
import "../src/VerificationRegistry.sol";

contract DeployScript is Script {
    uint256 private deployerPrivateKey;
    address private ownerAddress;

    function setUp() public {
        deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        ownerAddress = vm.envAddress("OWNER_ADDRESS");
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        new VerificationRegistry(ownerAddress);
        vm.stopBroadcast();
    }
}