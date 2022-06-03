const hre = require("hardhat");

async function main() {

    const TOKEN = await hre.ethers.getContractFactory("GDF");
    const token = await TOKEN.deploy();

    await token.deployed();

    console.log("AllCode token deployed to:", token.address);
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
});