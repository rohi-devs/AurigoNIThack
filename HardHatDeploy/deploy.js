// const hre = require("hardhat");

// async function main() {
//   const ProcurementSystem = await hre.ethers.getContractFactory("ProcurementSystem");
//   const procurementSystem = await ProcurementSystem.deploy();

//   await procurementSystem.deployed();

//   console.log(`ProcurementSystem deployed to: ${procurementSystem.address}`);
// }

// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });
const ethers = require("hardhat").ethers;
async function main() {
  // Get the contract factory
  const ProcurementSystem = await ethers.getContractFactory("ProcurementSystem");

  // Deploy the contract
  const procurementSystem = await ProcurementSystem.deploy();

  console.log("ProcurementSystem deployed to:", procurementSystem.address);

  // Ensure it's deployed and get the contract instance
  console.log(await procurementSystem.getAddress()); // This line waits for the deployment to be confirmed
  console.log("Contract is deployed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
