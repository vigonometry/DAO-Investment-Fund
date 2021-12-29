// const DAO = artifacts.require("LumiDAOToken");
const LumiDAOToken = artifacts.require("LumiDAOToken");

module.exports = async function (deployer) {
  // await deployer.deploy(DAO);
  await deployer.deploy(LumiDAOToken);
};
