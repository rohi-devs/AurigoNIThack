const ProcurementSystem = artifacts.require("ProcurementSystem");

module.exports = async function (deployer) {
  await deployer.deploy(ProcurementSystem);
};
