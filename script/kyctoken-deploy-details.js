const ethDeploy = require("../broadcast/KYCToken.s.sol/31337/run-latest.json");

const main = async () => {
    //console.log(ethDeploy.transactions);
    kycTokenAddress =
        ethDeploy.transactions.filter(t => t.contractName == "KYCToken")
            .map(t => t.contractAddress)[0];
    console.log(`${kycTokenAddress}`)
}

main();