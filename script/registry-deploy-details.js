const ethDeploy = require("../broadcast/VerificationRegistry.s.sol/31337/run-latest.json");

const main = async () => {
    //console.log(ethDeploy.transactions);
    registryAddress =
        ethDeploy.transactions.filter(t => t.contractName == "VerificationRegistry")
            .map(t => t.contractAddress)[0];
    console.log(`${registryAddress}`)
}

main();